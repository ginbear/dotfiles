#!/bin/bash
# Ghostty がフォーカス中でなければ音を鳴らすスクリプト

FRONTMOST=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true')
if [[ "$FRONTMOST" != "ghostty" ]]; then
  afplay /System/Library/Sounds/Glass.aiff
fi
