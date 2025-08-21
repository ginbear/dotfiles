#!/usr/bin/env bash
set -euo pipefail

# Requirements: gh (GitHub CLI v2.30+ 推奨), jq
command -v gh >/dev/null 2>&1 || { echo "gh not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not found"; exit 1; }

usage() {
  cat <<'USAGE'
Usage: gh-my-activity-org.sh -o ORG [-f YYYYMMDD] [-t YYYYMMDD] [--md]
  -o: organization (必須)
  -f: from (inclusive), default: today-14d
  -t: to   (inclusive), default: today
  --md: Markdown 見出しつきの整形出力

Examples:
  gh-my-activity-org.sh -o your-org
  gh-my-activity-org.sh -o your-org -f 20250801 -t 20250820 --md
USAGE
}

ORG=""
FROM_YYYYMMDD=""
TO_YYYYMMDD=""
AS_MD=false

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    -o) ORG="${2:-}"; shift 2 ;;
    -f) FROM_YYYYMMDD="${2:-}"; shift 2 ;;
    -t) TO_YYYYMMDD="${2:-}"; shift 2 ;;
    --md) AS_MD=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

[[ -n "$ORG" ]] || { echo "Error: -o ORG is required"; usage; exit 1; }

to_dash_date() { # yyyymmdd -> yyyy-mm-dd
  local s="$1"
  [[ "$s" =~ ^[0-9]{8}$ ]] || { echo "Invalid date: $s" >&2; exit 1; }
  echo "${s:0:4}-${s:4:2}-${s:6:2}"
}
is_bsd_date() { date -v-1d +%F >/dev/null 2>&1; }
date_n_days_ago() {
  local n="$1"
  if is_bsd_date; then date -v-"${n}"d +%F; else date -u -d "-${n} days" +%F; fi
}
date_today() {
  if is_bsd_date; then date +%F; else date -u +%F; fi
}

FROM_DATE="${FROM_YYYYMMDD:+$(to_dash_date "$FROM_YYYYMMDD")}"
TO_DATE="${TO_YYYYMMDD:+$(to_dash_date "$TO_YYYYMMDD")}"
FROM_DATE="${FROM_DATE:-$(date_n_days_ago 14)}"
TO_DATE="${TO_DATE:-$(date_today)}"

FROM_ISO="${FROM_DATE}T00:00:00Z"
TO_ISO_END="${TO_DATE}T23:59:59Z"
RANGE_DAYS="${FROM_DATE}..${TO_DATE}"

header() {
  $AS_MD && echo "## $1" || echo "$1"
}

# --- 1) 自分が作った Issue（org 横断） ---
issues_created_json="$(gh search issues \
  --owner "$ORG" \
  --author "@me" \
  --created "$RANGE_DAYS" \
  --limit 1000 \
  --json repository,title,url,createdAt \
  || true
)"

# --- 2) 自分が作った PR（org 横断） ---
prs_created_json="$(gh search prs \
  --owner "$ORG" \
  --author "@me" \
  --created "$RANGE_DAYS" \
  --limit 1000 \
  --json repository,title,url,createdAt \
  || true
)"

# --- 3) 自分がcloseしたIssue（org 横断） ---
# GitHub Searchでは直接closer情報が取得できないため、
# 実用的なアプローチとして、自分がコメントしたclosedなissueを取得
MY_LOGIN="$(gh api user --jq .login)"
issues_closed_by_me_json="$(gh search issues \
  --owner "$ORG" \
  --commenter "@me" \
  --state closed \
  --updated "$RANGE_DAYS" \
  --limit 100 \
  --json repository,title,url,closedAt \
  || echo '[]'
)"

# --- 4) 自分がコメントした Issue/PR（org 横断, updated レンジで粗く絞る） ---
issues_commented_json="$(gh search issues \
  --owner "$ORG" \
  --commenter "@me" \
  --updated "$RANGE_DAYS" \
  --limit 1000 \
  --json repository,title,url,updatedAt \
  || true
)"
prs_commented_json="$(gh search prs \
  --owner "$ORG" \
  --commenter "@me" \
  --updated "$RANGE_DAYS" \
  --limit 1000 \
  --json repository,title,url,updatedAt \
  || true
)"

# --- 出力 ---
$AS_MD && echo "# Activity in org: ${ORG} (${FROM_DATE} ～ ${TO_DATE})" || \
echo "Activity in org: ${ORG} (${FROM_DATE} ～ ${TO_DATE})"
echo

header "Issues I created"
echo "$issues_created_json" | jq -r '
  if (type=="array" and length>0) then
    sort_by(.createdAt) | .[]
    | "- [\(.repository.nameWithOwner)] \(.title) (\(.url))"
  else "- (none)" end
'
echo

header "PRs I created"
echo "$prs_created_json" | jq -r '
  if (type=="array" and length>0) then
    sort_by(.createdAt) | .[]
    | "- [\(.repository.nameWithOwner)] \(.title) (\(.url))"
  else "- (none)" end
'
echo

header "Issues I interacted with (closed)"
echo "$issues_closed_by_me_json" | jq -r '
  if (type=="array" and length>0) then
    sort_by(.closedAt // .updatedAt) | reverse | .[]
    | "- [\(.repository.nameWithOwner)] \(.title) (\(.url))"
  else "- (none)" end
'
echo

header "Issues/PRs I commented on"
jq -s '
  add
  | map({url, title, repo: .repository.nameWithOwner, ts: (.updatedAt // .createdAt // "")})
  | unique_by(.url)
  | sort_by(.ts) | reverse
  | if length>0 then .[] | "- [\(.repo)] \(.title) (\(.url))" else "- (none)" end
' <(echo "$issues_commented_json") <(echo "$prs_commented_json")

