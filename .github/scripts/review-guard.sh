#!/usr/bin/env bash
# Decide whether another automatic review may run for a pull request.
#
# Usage: review-guard.sh <pr-number> [current-comment-id]
#
# Counts earlier auto-review trigger comments on the PR. Pass the id of the
# comment that triggered the current run to exclude it from the counter.
# Prints `run` or `skip: <reason>` on stdout and exits 0.
#
# Environment: GH_REPO, GH_TOKEN, MAX_AUTO_REVIEWS_PER_PR (default 3).
set -euo pipefail

if [ -z "${GH_REPO:-}" ] || [ -z "${GH_TOKEN:-}" ]; then
  echo "GH_REPO and GH_TOKEN are required" >&2
  exit 1
fi

pr="${1:?pull request number is required}"
exclude="${2:-0}"
max="${MAX_AUTO_REVIEWS_PER_PR:-3}"

if [[ ! "$pr" =~ ^[0-9]+$ ]]; then
  echo "invalid pull request number: $pr" >&2
  exit 1
fi
if [[ ! "$exclude" =~ ^[0-9]+$ ]]; then
  echo "invalid comment id: $exclude" >&2
  exit 1
fi
if [[ ! "$max" =~ ^[0-9]+$ ]]; then
  echo "invalid review limit: $max" >&2
  exit 1
fi

# Issue comments and pull request review comments are separate endpoints. The
# review job also listens to pull_request_review_comment, so counting only
# issue comments would let an inline trigger bypass the limit.
#
# Count only maintainers' triggers: otherwise any outsider could exhaust the
# limit with marker comments and silently disable automatic review.
count="$(
  {
    gh api --paginate "repos/$GH_REPO/issues/$pr/comments"
    gh api --paginate "repos/$GH_REPO/pulls/$pr/comments"
  } | jq -s --arg marker '<!-- opencode-auto-review -->' --argjson excluded "$exclude" '
    add
    | map(select((.body // "") | contains($marker)))
    | map(select(.id != $excluded))
    | map(select((.author_association // "") as $a
        | ["OWNER", "MEMBER", "COLLABORATOR"] | index($a) != null))
    | length
  '
)"

if [ "$count" -ge "$max" ]; then
  echo "skip: auto-review limit $max reached ($count earlier request(s))"
else
  echo "run"
fi
