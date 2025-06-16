#!/bin/zsh
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open ghostty for production
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Custom Scripts
#
# Documentation:
# @raycast.description Say hello from zsh
# @raycast.author tora

# open -n -a Ghostty --env ENV_TYPE=production
open -h -a Ghostty --args -c ~/bin/start-prod-shell.sh

