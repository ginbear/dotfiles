#!/bin/bash
# Claude Code 遅延通知スクリプト
# permission prompt が1分間放置されたらポップアップで通知する
# async: true で呼ばれるため、スクリプト自体がバックグラウンド実行される

echo $$ > /tmp/claude-notify-pid
sleep 60
osascript -e 'display notification "確認が必要です" with title "Claude Code" sound name "Funk"'
