#!/bin/sh

## 基本tool
brew install wget
brew install nkf
brew install watch
brew install tree
brew install tmux

## 運用tool
brew install ansible
brew install gist
brew install tig
brew install Caskroom/cask/java  ## jenkins 依存
brew install jenkin
# To have launchd start jenkins at login:
#     ln -sfv /usr/local/opt/jenkins/*.plist ~/Library/LaunchAgents
# Then to load jenkins now:
#     launchctl load ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
# Or, if you don't want/need launchctl, you can just run:
#     jenkinss
brew install fabric

## 役立ち
brew install trash
