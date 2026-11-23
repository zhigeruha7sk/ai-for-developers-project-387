#!/usr/bin/env bash
# Regression tests for review-guard.sh, the per-PR cap on automatic reviews.
#
# The guard queries two GitHub endpoints with `gh api`. These tests put a fake
# `gh` on PATH that returns canned JSON, so the real guard logic runs unchanged.
#
# Usage: bash .github/scripts/review-guard.test.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
guard="$here/review-guard.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to run this test" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"
cat >"$tmp/bin/gh" <<'FAKE_GH'
#!/usr/bin/env bash
# Stand-in for `gh api --paginate`: return the canned comments for the endpoint
# in the last argument. The real guard calls the issues and pulls endpoints.
for arg in "$@"; do
  case "$arg" in
    */issues/*/comments) cat "${FAKE_ISSUE_COMMENTS:?}" ;;
    */pulls/*/comments) cat "${FAKE_PR_COMMENTS:?}" ;;
  esac
done
FAKE_GH
chmod +x "$tmp/bin/gh"

failures=0
cases=0

owner='{"id":1,"body":"<!-- opencode-auto-review --> /oc","author_association":"OWNER"}'
member='{"id":2,"body":"<!-- opencode-auto-review --> /oc","author_association":"MEMBER"}'
external='{"id":3,"body":"<!-- opencode-auto-review --> /oc","author_association":"NONE"}'
plain='{"id":4,"body":"ordinary comment","author_association":"OWNER"}'

comments() {
  local first=1 item
  printf '['
  for item in "$@"; do
    [ "$first" -eq 1 ] || printf ','
    printf '%s' "$item"
    first=0
  done
  printf ']'
}

expect() {
  local name="$1" expected="$2" issue="$3" pr="$4" max="${5:-3}" exclude="${6:-0}"
  local out status=0

  cases=$((cases + 1))
  printf '%s' "$issue" >"$tmp/issues.json"
  printf '%s' "$pr" >"$tmp/prs.json"

  out="$(PATH="$tmp/bin:$PATH" \
    GH_REPO="owner/repo" \
    GH_TOKEN="test-token" \
    FAKE_ISSUE_COMMENTS="$tmp/issues.json" \
    FAKE_PR_COMMENTS="$tmp/prs.json" \
    MAX_AUTO_REVIEWS_PER_PR="$max" \
    "$guard" 42 "$exclude" 2>"$tmp/stderr")" || status=$?

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

empty='[]'

expect "no comments" "run" "$empty" "$empty"
expect "ordinary comment is ignored" "run" "$(comments "$plain")" "$empty"
expect "one maintenance trigger" "run" "$(comments "$owner")" "$empty"
expect "two maintenance triggers" "run" "$(comments "$owner" "$member")" "$empty"
expect "three maintenance triggers" "skip: auto-review limit 3 reached (3 earlier request(s))" \
  "$(comments "$owner" "$member" "$owner")" "$empty"
expect "excluded current trigger" "run" \
  "$(comments "$owner" "$member" "$owner")" "$empty" 3 1
expect "external triggers do not spend the budget" "run" \
  "$(comments "$external" "$external" "$external")" "$empty"
expect "maintainers and external authors are counted separately" "run" \
  "$(comments "$owner" "$member" "$external")" "$empty"
expect "inline markers also count" "skip: auto-review limit 3 reached (3 earlier request(s))" \
  "$(comments "$owner" "$member")" "$(comments "$owner")"
expect "custom limit is enforced" "skip: auto-review limit 1 reached (1 earlier request(s))" \
  "$(comments "$owner")" "$empty" 1
expect "zero limit refuses every request" "skip: auto-review limit 0 reached (0 earlier request(s))" \
  "$empty" "$empty" 0

printf '\n%s case(s), %s failure(s)\n' "$cases" "$failures"
[ "$failures" -eq 0 ]
