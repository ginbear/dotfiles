#!/bin/sh

brew update
brew upgrade

## basic tools
brew install zsh
brew install vim
brew install wget
brew install htop
brew install nkf
brew install watch
brew install tree
brew install ag
brew install jq
brew install trash
brew install coreutils
brew install zsh-completions
brew install go
brew install ghq
brew tap peco/peco
brew install peco
brew install ipcalc
brew install tcptraceroute
brew install envchain

## ops tools
# brew install ansible
brew install tmux
brew install gist
brew install hub
brew install tig
brew install fabric
brew install pyenv
brew install terraform

## ricty
# check -> ruby -e 'puts "\u{2B60 2B61 2B80 2B81}"' 
brew list | grep ricty > /dev/null 2>&1 || (
  brew tap sanemat/font
  brew install Caskroom/cask/xquartz
#  brew install --patch-in-place --powerline --vim-powerline ricty
  brew install --vim-powerline ricty
  cp -f /usr/local/opt/ricty/share/fonts/Ricty*.ttf ~/Library/Fonts/
  fc-cache -vf
)

# jenkins
# brew install Caskroom/cask/java
# brew install jenkin
# To have launchd start jenkins at login:
#     ln -sfv /usr/local/opt/jenkins/*.plist ~/Library/LaunchAgents
# Then to load jenkins now:
#     launchctl load ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
# Or, if you don't want/need launchctl, you can just run:
#     jenkinss

brew cleanup
