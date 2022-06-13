#!/bin/sh

brew -v || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew update
brew upgrade

## basic tools
brew install zsh
mkdir ~/.zsh/
brew install fish
brew install bat
brew install coreutils
brew install ghq
brew install go
brew install htop
brew install ipcalc
brew install jq
brew install nkf
brew install tcptraceroute
brew install trash
brew install tree
brew install vim
brew install watch
brew install wget
brew tap peco/peco
brew install peco
brew install ripgrep
brew install sd

### lsd
brew install lsd
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font --cask
# 一度 iterm2 を再起動する
# iTerm2 > Preferences > Profiles > Text > Non-ASCII-Font > Change Font
# ref https://github.com/Peltoche/lsd/issues/199


## ops tools
brew install envchain
brew install tmux
brew install gist
brew install hub
brew install tig
brew install pyenv
brew install tfenv
brew install pssh
brew install awscli

## rbenv
brew install rbenv ruby-build
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

brew cleanup
