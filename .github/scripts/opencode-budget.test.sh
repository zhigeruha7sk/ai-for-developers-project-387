#!/usr/bin/env bash
# Regression tests for opencode-budget.sh, the per-PR run budget gate.
#
# The gate reads the PR head and the Actions run history through `gh api`.
# These tests put a fake `gh` on PATH, so the real gate logic runs unchanged.
#
# Usage: bash .github/scripts/opencode-budget.test.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gate="$here/opencode-budget.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to run this test" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"
cat >"$tmp/bin/gh" <<'FAKE_GH'
#!/usr/bin/env bash
# Stand-in for `gh api`: the PR endpoint returns a head SHA, the runs endpoint
# returns the canned run history. Error flags exercise the fail-closed paths.
case "$*" in
  *"/pulls/"*)
    [ "${FAKE_PR_ERROR:-0}" = "1" ] && exit 1
    printf '%s\n' "${FAKE_SHA:?}"
    ;;
  *"/actions/workflows/"*)
    [ "${FAKE_RUNS_ERROR:-0}" = "1" ] && exit 1
    cat "${FAKE_RUNS:?}"
    ;;
  *) exit 1 ;;
esac
FAKE_GH
chmod +x "$tmp/bin/gh"

failures=0
cases=0

runs_json() {
  local items=("$@") first=1 item
  printf '{"workflow_runs":['
  for item in "${items[@]}"; do
    [ "$first" -eq 1 ] || printf ','
    printf '%s' "$item"
    first=0
  done
  printf ']}'
}

run() {
  local id="$1" attempts="$2" status="${3:-completed}" conclusion="${4:-success}" title="${5:-opencode-request pr-42}"
  printf '{"id":%s,"run_attempt":%s,"status":"%s","conclusion":"%s","display_title":"%s"}' \
    "$id" "$attempts" "$status" "$conclusion" "$title"
}

expect() {
  local name="$1" allowed="$2" used="$3" reason="$4" runs="$5" attempt="${6:-1}" limit="${7:-3}"
  local outfile="$tmp/out" status=0

  cases=$((cases + 1))
  : >"$outfile"
  printf '%s' "$runs" >"$tmp/runs.json"

  PATH="$tmp/bin:$PATH" \
    GH_REPO="owner/repo" \
    GH_TOKEN="test-token" \
    PR_NUMBER="42" \
    RUN_ID="100" \
    RUN_ATTEMPT="$attempt" \
    OPENCODE_PR_RUN_LIMIT="$limit" \
    FAKE_SHA="abc123" \
    FAKE_RUNS="$tmp/runs.json" \
    GITHUB_OUTPUT="$outfile" \
    bash "$gate" >/dev/null 2>"$tmp/stderr" || status=$?

  local got_allowed got_used got_reason
  got_allowed="$(sed -n 's/^allowed=//p' "$outfile")"
  got_used="$(sed -n 's/^used=//p' "$outfile")"
  got_reason="$(sed -n 's/^reason=//p' "$outfile")"

  if [ "$status" -ne 0 ]; then
    printf 'FAIL %s: gate exited %s\n' "$name" "$status" >&2
    sed 's/^/    /' "$tmp/stderr" >&2
    failures=$((failures + 1))
  elif [ "$got_allowed" != "$allowed" ] || [ "$got_used" != "$used" ] || [ "$got_reason" != "$reason" ]; then
    printf 'FAIL %s: expected allowed=%s used=%s reason=%s, got allowed=%s used=%s reason=%s\n' \
      "$name" "$allowed" "$used" "$reason" "$got_allowed" "$got_used" "$got_reason" >&2
    sed 's/^/    /' "$tmp/stderr" >&2
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

expect "first run is allowed" "true" "1" "" \
  "$(runs_json)"

expect "attempt at the limit is allowed" "true" "3" "" \
  "$(runs_json "$(run 90 2)")"

expect "attempt over the limit is refused" "false" "4" "limit_exhausted" \
  "$(runs_json "$(run 90 2)" "$(run 91 1)")"

expect "re-run counts its own attempt" "false" "4" "limit_exhausted" \
  "$(runs_json "$(run 90 1)" "$(run 91 1)")" 2

expect "queued runs are not charged" "true" "1" "" \
  "$(runs_json "$(run 90 5 queued "")")"

expect "skipped runs are not charged" "true" "1" "" \
  "$(runs_json "$(run 90 5 completed skipped)")"

expect "other pull requests are not charged" "true" "1" "" \
  "$(runs_json "$(run 90 5 completed success 'opencode-request pr-99')")"

expect "review runs are not charged" "true" "1" "" \
  "$(runs_json "$(run 90 5 completed success 'opencode-review pr-42')")"

expect "triage runs are not charged" "true" "1" "" \
  "$(runs_json "$(run 90 5 completed success 'opencode-triage pr-42')")"

expect "current run id is excluded" "true" "2" "" \
  "$(runs_json "$(run 100 3)")" 2

expect "custom limit is enforced" "false" "2" "limit_exhausted" \
  "$(runs_json "$(run 90 1)")" 1 1

expect_infra() {
  local name="$1" pr_error="$2" runs_error="$3"
  local outfile="$tmp/out" status=0

  cases=$((cases + 1))
  : >"$outfile"
  printf '%s' "$(runs_json)" >"$tmp/runs.json"

  PATH="$tmp/bin:$PATH" \
    GH_REPO="owner/repo" \
    GH_TOKEN="test-token" \
    PR_NUMBER="42" \
    RUN_ID="100" \
    RUN_ATTEMPT="1" \
    OPENCODE_PR_RUN_LIMIT="3" \
    FAKE_SHA="abc123" \
    FAKE_RUNS="$tmp/runs.json" \
    FAKE_PR_ERROR="$pr_error" \
    FAKE_RUNS_ERROR="$runs_error" \
    GITHUB_OUTPUT="$outfile" \
    bash "$gate" >/dev/null 2>"$tmp/stderr" || status=$?

  local got_allowed got_reason
  got_allowed="$(sed -n 's/^allowed=//p' "$outfile")"
  got_reason="$(sed -n 's/^reason=//p' "$outfile")"

  if [ "$status" -ne 1 ]; then
    printf 'FAIL %s: expected exit 1, got %s\n' "$name" "$status" >&2
    sed 's/^/    /' "$tmp/stderr" >&2
    failures=$((failures + 1))
  elif [ "$got_allowed" != "false" ] || [ "$got_reason" != "infra" ]; then
    printf 'FAIL %s: expected allowed=false reason=infra, got allowed=%s reason=%s\n' \
      "$name" "$got_allowed" "$got_reason" >&2
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

expect_infra "cannot read the pull request" 1 0
expect_infra "cannot read the run history" 0 1

printf '\n%s case(s), %s failure(s)\n' "$cases" "$failures"
[ "$failures" -eq 0 ]
