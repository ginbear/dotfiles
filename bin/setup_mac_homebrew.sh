#!/bin/sh

## basic tools
brew install wget
brew install htop
brew install nkf
brew install watch
brew install tree
brew install ag
brew install trash
brew install coreutils
brew tap peco/peco
brew install peco

## ops tools
# brew install ansible
brew install tmux
brew install gist
brew install tig
brew install fabric

## ricty
brew tap sanemat/font
brew install Caskroom/cask/xquartz
brew install ricty

cp -f /usr/local/opt/ricty/share/fonts/Ricty*.ttf ~/Library/Fonts/
fc-cache -vf

# jenkins
# brew install Caskroom/cask/java
# brew install jenkin
# To have launchd start jenkins at login:
#     ln -sfv /usr/local/opt/jenkins/*.plist ~/Library/LaunchAgents
# Then to load jenkins now:
#     launchctl load ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
# Or, if you don't want/need launchctl, you can just run:
#     jenkinss
