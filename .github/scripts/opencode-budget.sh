#!/usr/bin/env bash
# Decide whether one /oc request on a pull request may call the model.
#
# The counter is the Actions run history, not a file and not a PR comment:
# every workflow run and every re-run attempt is recorded by GitHub, the
# history is append-only for a token with `actions: read`, and the agent cannot
# edit it from a comment. A new pull request number produces a new title, so it
# starts with a fresh budget; requests on plain issues are not limited.
#
# Usage:
#   GH_REPO=owner/repo GH_TOKEN=... PR_NUMBER=16 RUN_ID=... RUN_ATTEMPT=1 \
#     GITHUB_OUTPUT=... OPENCODE_PR_RUN_LIMIT=3 ./opencode-budget.sh
#
# Writes these keys to $GITHUB_OUTPUT: allowed, used, limit, reason, detail,
# last_sha, pr. Exits non-zero when the history cannot be read; the caller must
# treat that as an infrastructure failure and must not call the model.
set -euo pipefail

repo="${GH_REPO:?GH_REPO must be set}"
run_id="${RUN_ID:?RUN_ID must be set}"
run_attempt="${RUN_ATTEMPT:-1}"
limit="${OPENCODE_PR_RUN_LIMIT:-3}"
pr_number="${PR_NUMBER:-}"
workflow_file="opencode.yml"

# Titles are set by `run-name` in .github/workflows/opencode.yml. Only runs that
# carried a command are counted; a plain comment gets the `opencode-idle` title
# and never reaches this script, but the title check keeps old runs out too.
expected_title="opencode-request pr-${pr_number}"

output() {
  printf '%s=%s\n' "$1" "$2" >>"${GITHUB_OUTPUT:?GITHUB_OUTPUT must be set}"
}

if [ -z "$pr_number" ]; then
  echo "not a pull request: the per-PR budget does not apply" >&2
  output allowed true
  output used 0
  output limit "$limit"
  output reason ""
  output detail "not a pull request"
  output last_sha ""
  output pr ""
  exit 0
fi

# The last SHA is what a human compares with the logs and the PR head.
if ! last_sha=$(gh api "repos/$repo/pulls/$pr_number" --jq .head.sha); then
  echo "cannot read pull request #$pr_number" >&2
  output allowed false
  output used 0
  output limit "$limit"
  output reason infra
  output detail "cannot read pull request #$pr_number"
  output last_sha ""
  output pr "$pr_number"
  exit 1
fi

# `gh api --paginate` emits one JSON object per page; `jq -s` merges them.
if ! all_runs=$(gh api --paginate \
  "repos/$repo/actions/workflows/$workflow_file/runs?per_page=100" |
  jq -s '[.[].workflow_runs[]]'); then
  echo "cannot read the Actions run history" >&2
  output allowed false
  output used 0
  output limit "$limit"
  output reason infra
  output detail "cannot read the Actions run history"
  output last_sha "$last_sha"
  output pr "$pr_number"
  exit 1
fi

# Count the attempts of all earlier runs for this pull request:
# - the current run is excluded because its own attempt is added below;
# - queued runs have not been admitted yet and are not counted;
# - skipped runs never reached the agent (no /oc, bot author, etc.);
# - a re-run increments `run_attempt`, so a cancellation, timeout or Re-run
#   is charged exactly like the original attempt.
prior_attempts=$(jq -r \
  --arg title "$expected_title" \
  --argjson run_id "$run_id" '
    def normalized_title: (.display_title // "" | gsub("\\s+"; " ") | gsub("^ | $"; ""));
    [
      .[]
      | select(.id != $run_id)
      | select(normalized_title == $title)
      | select(.status as $s | (["queued", "pending", "requested", "waiting"] | index($s)) | not)
      | select(.conclusion != "skipped")
      | (.run_attempt // 1)
    ]
    | add // 0
  ' <<<"$all_runs")

used=$((prior_attempts + run_attempt))

if [ "$used" -le "$limit" ]; then
  allowed=true
  reason=""
  detail="attempt $used of $limit"
else
  allowed=false
  reason=limit_exhausted
  detail="the budget of $limit runs for pull request #$pr_number is exhausted"
fi

output allowed "$allowed"
output used "$used"
output limit "$limit"
output reason "$reason"
output detail "$detail"
output last_sha "$last_sha"
output pr "$pr_number"

printf 'budget for pull request #%s: %s (%s of %s)\n' \
  "$pr_number" "$allowed" "$used" "$limit" >&2
