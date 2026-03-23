#!/usr/bin/env bash
# PostToolUse hook: Bash コマンドと出力先頭をログファイルに追記
# cmux ペインで tail -f して表示する想定
# CMUX_COMMAND_LOG=1 で有効化。セッションごとに別ファイルに出力。

set -euo pipefail

[[ "${CMUX_COMMAND_LOG:-}" == "1" ]] || exit 0

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
[[ -z "$SESSION_ID" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

LOGDIR="/tmp/claude-command-logs"
mkdir -p "$LOGDIR"
LOGFILE="${LOGDIR}/${SESSION_ID}.log"

STDOUT=$(echo "$INPUT" | jq -r '.tool_response.stdout // empty')
TIMESTAMP=$(date +%H:%M:%S)

# ログに追記
{
  echo "[$TIMESTAMP] \$ $COMMAND"
  if [[ -n "$STDOUT" ]]; then
    echo "$STDOUT" | head -5 | sed 's/^/  /'
    TOTAL=$(echo "$STDOUT" | wc -l | tr -d ' ')
    if [[ "$TOTAL" -gt 5 ]]; then
      echo "  ... ($TOTAL lines total)"
    fi
  fi
  echo ""
} >> "$LOGFILE"

exit 0
