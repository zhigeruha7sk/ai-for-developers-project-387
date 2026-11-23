#!/usr/bin/env bash
# Publish the result of an /oc run without calling the model.
#
# This script only reads the outputs of the budget gate and the agent job. It
# runs in a separate job that waits for the agent to stop, so it still works
# after a timeout, an infrastructure failure or an exhausted budget.
#
# Reasons:
#   limit_exhausted - the per-PR run budget is used up;
#   timeout         - the single agent invocation hit its step timeout;
#   infra           - the budget check failed or the agent toolchain was not
#                     ready (missing key, unreachable installer, failed setup);
#   agent_failed    - any other failure of the agent step.
#
# The report is a pull request comment. Its text is informational only: the
# budget lives in the Actions run history and cannot be changed by editing it.
set -euo pipefail

repo="${GH_REPO:?GH_REPO must be set}"
number="${NUMBER:-}"
is_pr="${IS_PR:-false}"
run_url="${RUN_URL:?RUN_URL must be set}"

budget_result="${BUDGET_RESULT:-}"
budget_allowed="${BUDGET_ALLOWED:-}"
budget_reason="${BUDGET_REASON:-}"
budget_detail="${BUDGET_DETAIL:-}"
budget_used="${BUDGET_USED:-0}"
budget_limit="${BUDGET_LIMIT:-0}"
budget_last_sha="${BUDGET_LAST_SHA:-}"
agent_result="${AGENT_RESULT:-}"
agent_reason="${AGENT_REASON:-}"
agent_detail="${AGENT_DETAIL:-}"

reason=""
detail=""

if [ "$budget_result" = "failure" ]; then
  reason="infra"
  detail="The budget check failed, so the model was not called."
elif [ "$budget_allowed" = "false" ]; then
  reason="${budget_reason:-limit_exhausted}"
  detail="$budget_detail"
elif [ -n "$agent_reason" ]; then
  reason="$agent_reason"
  detail="$agent_detail"
elif [ "$agent_result" = "failure" ]; then
  reason="agent_failed"
  detail="The agent job failed without a classified reason."
elif [ "$agent_result" = "cancelled" ]; then
  reason="agent_failed"
  detail="The agent job was cancelled."
fi

if [ -z "$reason" ]; then
  echo "nothing to report"
  exit 0
fi

if [ -z "$number" ]; then
  echo "::error::$reason: no issue or pull request number in the event"
  exit 1
fi

last_sha=""
if [ "$is_pr" = "true" ]; then
  last_sha=$(gh api "repos/$repo/pulls/$number" --jq .head.sha 2>/dev/null || true)
fi
if [ -z "$last_sha" ]; then
  last_sha="$budget_last_sha"
fi

if [ -z "$last_sha" ]; then
  last_sha="unknown"
fi

if [ "$is_pr" = "true" ] && [ "$budget_limit" -gt 0 ]; then
  if [ "$budget_used" -gt "$budget_limit" ]; then
    budget_used="$budget_limit"
  fi
  budget_line="- **Бюджет PR:** ${budget_used} из ${budget_limit} запусков"
elif [ "$is_pr" = "true" ]; then
  budget_line="- **Бюджет PR:** не удалось проверить"
else
  budget_line="- **Бюджет PR:** не применяется (issue)"
fi

body=$(cat <<EOF
<!-- opencode-budget-report -->
## OpenCode: нужен человек

- **Причина:** \`$reason\`
- **Последний SHA:** \`$last_sha\`
$budget_line
- **Логи:** $run_url
- **Статус:** нужен человек

$detail

Следующее действие выбирает человек. Автоматический цикл исправлений для этого
запроса не запускается. Если причина не совпадает с тем, что видно в логах,
проверьте лог задания: неизвестная причина не угадывается автоматически.
EOF
)

marker='<!-- opencode-budget-report -->'
comment_id=""
if comments=$(gh api --paginate "repos/$repo/issues/$number/comments?per_page=100" 2>/dev/null); then
  comment_id=$(jq -rs --arg marker "$marker" \
    '[.[][] | select((.body // "") | contains($marker))] | last | .id // empty' \
    <<<"$comments")
fi

if [ -n "$comment_id" ]; then
  if ! gh api --method PATCH "repos/$repo/issues/comments/$comment_id" \
    -f body="$body" >/dev/null; then
    gh api --method POST "repos/$repo/issues/$number/comments" \
      -f body="$body" >/dev/null
  fi
else
  gh api --method POST "repos/$repo/issues/$number/comments" \
    -f body="$body" >/dev/null
fi

# A PR that needs a human is marked with the repository's canonical state label.
if [ "$reason" = "limit_exhausted" ] && [ "$is_pr" = "true" ] && [ -n "$number" ]; then
  gh pr edit "$number" --add-label ready-for-human >/dev/null 2>&1 ||
    echo "::warning::could not add the ready-for-human label"
fi

{
  printf '### OpenCode: нужен человек\n\n'
  printf -- "- Причина: \`%s\`\n" "$reason"
  printf -- "- Последний SHA: \`%s\`\n" "$last_sha"
  printf -- '- Логи: %s\n' "$run_url"
} >>"${GITHUB_STEP_SUMMARY:-/dev/null}"

printf 'reported %s for #%s\n' "$reason" "$number" >&2
