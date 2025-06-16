#!/bin/zsh

LOGFILE=~/.logs/zsh-session-$(date +%F-%H%M%S).log
mkdir -p ~/.logs

# ENV_TYPE を export して zsh に渡す
# script の中で ENV_TYPE=production が有効になる
ENV_TYPE=production script -q "$LOGFILE" zsh
