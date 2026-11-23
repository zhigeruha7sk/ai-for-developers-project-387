#!/usr/bin/env bash
# Regression tests for triage-guard.sh, the live-state gate that decides whether
# automatic triage may write to an issue.
#
# The guard queries GitHub with `gh api`. These tests put a fake `gh` on PATH
# that returns a canned JSON document, so the real guard logic runs unchanged.
#
# Usage: bash .github/scripts/triage-guard.test.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
guard="$here/triage-guard.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to run this test" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"
cat >"$tmp/bin/gh" <<'FAKE_GH'
#!/usr/bin/env bash
# Stand-in for `gh api`: return the canned issue state for the guard to parse.
cat "${FAKE_ISSUE_JSON:?}"
FAKE_GH
chmod +x "$tmp/bin/gh"

failures=0
cases=0

expect() {
  local name="$1" expected="$2" json="$3"
  local out status=0
  cases=$((cases + 1))

  printf '%s' "$json" >"$tmp/issue.json"
  out="$(PATH="$tmp/bin:$PATH" \
    GH_REPO="owner/repo" \
    GH_TOKEN="test-token" \
    FAKE_ISSUE_JSON="$tmp/issue.json" \
    "$guard" 42 2>"$tmp/stderr")" || status=$?

  if [ "$status" -ne 0 ]; then
    printf 'FAIL %s: guard exited %s\n' "$name" "$status" >&2
    sed 's/^/    /' "$tmp/stderr" >&2
    failures=$((failures + 1))
  elif [ "$out" != "$expected" ]; then
    printf 'FAIL %s: expected %q, got %q\n' "$name" "$expected" "$out" >&2
    sed 's/^/    /' "$tmp/stderr" >&2
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

expect "human without labels" "run" \
  '{"labels":[],"author_type":"User","is_pr":false}'

# `needs-triage` is set by the workflow itself, so it must not block.
expect "needs-triage does not block" "run" \
  '{"labels":["needs-triage"],"author_type":"User","is_pr":false}'

expect "pull request" "skip" \
  '{"labels":[],"author_type":"User","is_pr":true}'

expect "bot author" "skip" \
  '{"labels":[],"author_type":"Bot","is_pr":false}'

for label in skip-triage needs-info ready-for-agent ready-for-human wontfix; do
  expect "label $label" "skip" \
    "{\"labels\":[\"$label\"],\"author_type\":\"User\",\"is_pr\":false}"
done

printf '\n%s case(s), %s failure(s)\n' "$cases" "$failures"
[ "$failures" -eq 0 ]
