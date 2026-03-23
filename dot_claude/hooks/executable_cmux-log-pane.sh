#!/usr/bin/env bash
# SessionStart hook: cmux 内なら下にペインを生やして tail -f でログを表示
# CMUX_COMMAND_LOG=1 のときのみ動作

set -euo pipefail

[[ "${CMUX_COMMAND_LOG:-}" == "1" ]] || exit 0
[[ -n "${CMUX_SOCKET_PATH:-}" ]] || exit 0

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
[[ -z "$SESSION_ID" ]] && exit 0

LOGDIR="/tmp/claude-command-logs"
mkdir -p "$LOGDIR"
LOGFILE="${LOGDIR}/${SESSION_ID}.log"
touch "$LOGFILE"

# 下にペインを生やして tail -f を実行
RESULT=$(cmux new-split down)
SURFACE=$(echo "$RESULT" | awk '{print $2}')

cmux send --surface "$SURFACE" "tail -f $LOGFILE\n"

exit 0
