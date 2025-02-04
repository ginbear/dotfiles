#!/bin/sh

brew -v || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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
# brew install vim
brew install watch
brew install wget
brew tap peco/peco
brew install peco
brew install ripgrep
brew install sd
brew install neovim
brew install powerlevel10k # https://github.com/romkatv/powerlevel10k

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

brew cleanup
