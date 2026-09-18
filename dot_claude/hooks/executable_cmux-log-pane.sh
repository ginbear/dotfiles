#!/usr/bin/env bash
# SessionStart hook: ターミナルにペインを生やして tail -f でログを表示
# CLAUDE_COMMAND_LOG=1 のときのみ動作
#
# CLAUDE_LOG_PANE_MODE で表示方法を切り替え:
#   split  - Ghostty スプリット (AppleScript 経由、アクセシビリティ許可が必要)
#   window - Ghostty 新ウィンドウ (AppleScript 不要)
#   (デフォルト: window)
#
# 対応ターミナル:
#   - Ghostty (macOS): split / window
#   - cmux: cmux new-split (コメントアウト中)

set -euo pipefail

[[ "${CLAUDE_COMMAND_LOG:-${CMUX_COMMAND_LOG:-}}" == "1" ]] || exit 0

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
[[ -z "$SESSION_ID" ]] && exit 0

LOGDIR="/tmp/claude-command-logs"
mkdir -p "$LOGDIR"
LOGFILE="${LOGDIR}/${SESSION_ID}.log"
touch "$LOGFILE"

PANE_MODE="${CLAUDE_LOG_PANE_MODE:-window}"

# --- Ghostty (macOS) ---
if [[ "${TERM_PROGRAM:-}" == "ghostty" ]]; then
  case "$PANE_MODE" in
    split)
      # AppleScript で Cmd+Shift+D (new_split:down) → クリップボード経由でコマンド送信
      # keystroke は IME を通過するため、クリップボードにコマンドを入れて Cmd+V で貼り付け
      # システム環境設定 > アクセシビリティ で Ghostty への許可が必要
      TAIL_CMD="tail -f ${LOGFILE}"
      osascript <<APPLESCRIPT
        -- 現在のクリップボードを退避
        set oldClipboard to the clipboard

        tell application "System Events"
          tell process "ghostty"
            -- Cmd+Shift+D = new_split:down
            keystroke "d" using {command down, shift down}
          end tell
        end tell

        delay 0.5

        -- クリップボードにコマンドをセットして貼り付け
        set the clipboard to "${TAIL_CMD}"
        tell application "System Events"
          tell process "ghostty"
            keystroke "v" using {command down}
          end tell
        end tell

        delay 0.2

        tell application "System Events"
          tell process "ghostty"
            key code 36 -- Return
          end tell
        end tell

        -- クリップボードを復元
        delay 0.2
        set the clipboard to oldClipboard
APPLESCRIPT
      ;;
    window|*)
      # 新ウィンドウで tail -f を実行 (AppleScript 不要)
      open -na Ghostty.app --args -e /bin/bash -c "exec tail -f '${LOGFILE}'"
      ;;
  esac
  exit 0
fi

# --- cmux: コメントアウト中（戻す場合は下記を有効化） ---
# if [[ -n "${CMUX_SOCKET_PATH:-}" ]]; then
#   RESULT=$(cmux new-split down)
#   SURFACE=$(echo "$RESULT" | awk '{print $2}')
#   cmux send --surface "$SURFACE" "tail -f $LOGFILE\n"
#   exit 0
# fi

exit 0
