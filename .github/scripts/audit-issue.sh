#!/usr/bin/env bash
# Create one audit issue per finding key, idempotently.
#
# The finding key is stored in the issue body as an HTML comment. A repeated
# audit run with the same key finds that comment and exits without creating a
# second issue. The agent is not allowed to call `gh issue create` directly.
set -euo pipefail

KEY="${1:-}"
TITLE="${2:-}"
BODY_FILE="${3:-}"

if [[ ! "$KEY" =~ ^[a-z0-9][a-z0-9-]{2,63}$ ]]; then
  echo "::error::invalid finding key: '$KEY' (expected lowercase letters, digits and dashes)" >&2
  exit 2
fi

if [[ -z "$TITLE" ]]; then
  echo "::error::issue title is empty" >&2
  exit 2
fi

if [[ ! -s "$BODY_FILE" ]]; then
  echo "::error::finding body file is missing or empty: '$BODY_FILE'" >&2
  exit 2
fi

REPO="${GH_REPO:-${GITHUB_REPOSITORY:-}}"
if [[ -z "$REPO" ]]; then
  echo "::error::GH_REPO or GITHUB_REPOSITORY is required" >&2
  exit 2
fi
export GH_REPO="$REPO"

MARKER="<!-- app-audit-finding:${KEY} -->"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
ISSUES_FILE="$TMP_DIR/issues.json"
BODY_TMP="$TMP_DIR/body.md"

# The label narrows the search and makes the audit issues easy to find. The
# marker, not the title, is the deduplication key: a model may reword a title
# between runs, but the key stays stable.
if ! gh issue list \
  --state all \
  --label app-audit \
  --limit 200 \
  --json number,title,url,state,body >"$ISSUES_FILE" 2>"$TMP_DIR/list.err"; then
  echo "::warning::cannot list issues by the app-audit label, falling back to all issues" >&2
  cat "$TMP_DIR/list.err" >&2 || true
  gh issue list \
    --state all \
    --limit 500 \
    --json number,title,url,state,body >"$ISSUES_FILE"
fi

EXISTING="$(jq -r --arg marker "$MARKER" '
  [ .[] | select((.body // "") | contains($marker)) ] |
  first |
  if . then "\(.number)\t\(.state)\t\(.url)" else empty end
' "$ISSUES_FILE")"

if [[ -n "$EXISTING" ]]; then
  IFS=$'\t' read -r number state url <<<"$EXISTING"
  printf 'existing #%s (%s) %s\n' "$number" "$state" "$url"
  exit 0
fi

{
  printf '%s\n\n' "$MARKER"
  cat "$BODY_FILE"
  printf '\n\n---\n'
  printf '*Создано автоматически workflow `app-audit`'
  if [[ -n "${AUDIT_RUN_URL:-}" ]]; then
    printf ' (run: %s)' "$AUDIT_RUN_URL"
  fi
  printf '.*\n'
} >"$BODY_TMP"

CREATED_URL="$(gh issue create \
  --title "$TITLE" \
  --body-file "$BODY_TMP" \
  --label app-audit \
  --label bug)"
printf 'created %s\n' "$CREATED_URL"
