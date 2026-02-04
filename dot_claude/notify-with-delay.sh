#!/bin/bash
# Claude Code 遅延通知スクリプト
# 1分後にポップアップと音を出す（キャンセルされなければ）

PID_FILE="/tmp/claude-notify-pid"
MESSAGE="${1:-作業が完了しました}"

# 呼び出し時点でウィンドウタイトルを取得（1分後にはフォーカスが変わっている可能性があるため）
WINDOW_TITLE=$(osascript -e 'tell application "System Events" to get name of first window of (first process whose frontmost is true)' 2>/dev/null || echo "")

# 既存のタイマーがあればキャンセル
if [ -f "$PID_FILE" ]; then
  kill $(cat "$PID_FILE") 2>/dev/null
  rm -f "$PID_FILE"
fi

# 1分後に通知するプロセスをバックグラウンドで起動（stdin/stdout/stderr を閉じて完全に切り離す）
(
  sleep 60
  if [ -n "$WINDOW_TITLE" ]; then
    terminal-notifier -title 'Claude Code' -subtitle "$WINDOW_TITLE" -message "$MESSAGE" -sender com.apple.Terminal
  else
    terminal-notifier -title 'Claude Code' -message "$MESSAGE" -sender com.apple.Terminal
  fi
  afplay /System/Library/Sounds/Hero.aiff
) </dev/null >/dev/null 2>&1 &
echo $! > "$PID_FILE"
disown
