#!/usr/bin/env bash
# Decide whether automatic triage may write to an issue, based on its LIVE state.
#
# The workflow reads the `issues: opened` payload for a cheap filter, but that
# payload cannot see labels or edits made after the issue was opened. This
# script re-reads the issue through the API immediately before any write.
#
# Usage: GH_REPO=owner/repo GH_TOKEN=... ./triage-guard.sh <issue-number>
# Prints exactly one word to stdout: "run" or "skip".
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <issue-number>" >&2
  exit 2
fi

repo="${GH_REPO:?GH_REPO must be set}"
number="$1"

state=$(gh api "repos/$repo/issues/$number" \
  --jq '{labels: [.labels[].name], author_type: .user.type, author_association: .author_association, is_pr: (.pull_request != null)}')

printf 'live issue #%s: %s\n' "$number" "$state" >&2

if [ "$(jq -r '.is_pr' <<<"$state")" = "true" ]; then
  echo "skip: pull request" >&2
  echo "skip"
  exit 0
fi

if [ "$(jq -r '.author_type' <<<"$state")" = "Bot" ]; then
  echo "skip: bot author" >&2
  echo "skip"
  exit 0
fi

# Automatic triage is limited to trusted authors. External contributors and
# first-time reporters must not be able to spend agent runs or have the PAT
# comment posted on their behalf.
association=$(jq -r '.author_association // "NONE"' <<<"$state")
case "$association" in
  OWNER | MEMBER | COLLABORATOR) ;;
  *)
    echo "skip: untrusted author association ($association)" >&2
    echo "skip"
    exit 0
    ;;
esac

# `needs-triage` is deliberately absent: this workflow sets it itself.
for label in skip-triage needs-info ready-for-agent ready-for-human wontfix; do
  if jq -e --arg label "$label" '.labels | index($label) != null' >/dev/null <<<"$state"; then
    echo "skip: label $label" >&2
    echo "skip"
    exit 0
  fi
done

echo "run"
