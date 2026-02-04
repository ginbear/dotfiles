#!/bin/bash
# 遅延通知をキャンセルするスクリプト

PID_FILE="/tmp/claude-notify-pid"

if [ -f "$PID_FILE" ]; then
  kill $(cat "$PID_FILE") 2>/dev/null
  rm -f "$PID_FILE"
fi
