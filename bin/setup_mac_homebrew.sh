#!/bin/sh

brew -v || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew update
brew upgrade

## basic tools
brew install zsh
mkdir ~/.zsh/
brew install fish
# brew install ag # to ripgrep
brew install bat
brew install coreutils
brew install ghq
brew install go
brew install htop
brew install ipcalc
brew install jq
brew install nkf
# brew install nodejs
brew install tcptraceroute
brew install trash
brew install tree
brew install vim
brew install watch
brew install wget
# brew install zsh-completions
# brew install rmtrash
brew tap peco/peco
brew install peco
brew install ripgrep
brew install sd

### lsd
brew install lsd
brew tap homebrew/cask-fonts
brew cask install font-hack-nerd-font
# 一度 iterm2 を再起動する
# iTerm2 > Preferences > Profiles > Text > Non-ASCII-Font > Change Font
# ref https://github.com/Peltoche/lsd/issues/199


## ops tools
# brew install ansible
brew install envchain
brew install tmux
brew install gist
brew install hub
brew install tig
brew install fabric
brew install pyenv
# brew install terraform
brew install tfenv
brew install pssh
brew install awscli
# brew install akamai
brew install fftw httping

## mackerel
brew tap mackerelio/mackerel-agent
brew install mkr

## rbenv
brew install rbenv ruby-build
rbenv install 2.2.1
rbenv install 2.3.1
rbenv install 2.4.1
rbenv install 2.5.1
rbenv global 2.5.1
rbenv exec gem install bundler
rbenv rehash

## ricty
# check -> ruby -e 'puts "\u{2B60 2B61 2B80 2B81}"' 
brew list | grep ricty > /dev/null 2>&1 || (
  brew tap sanemat/font
  brew install Caskroom/cask/xquartz
  brew install ricty --with-powerline
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
