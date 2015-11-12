#!/bin/sh

## basic tools
brew install wget
brew install nkf
brew install watch
brew install tree
brew install tmux
brew install ag
brew install trash

## ops tools
brew install ansible
brew install gist
brew install tig
brew install fabric

# jenkins
# brew install Caskroom/cask/java
# brew install jenkin
# To have launchd start jenkins at login:
#     ln -sfv /usr/local/opt/jenkins/*.plist ~/Library/LaunchAgents
# Then to load jenkins now:
#     launchctl load ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
# Or, if you don't want/need launchctl, you can just run:
#     jenkinss
