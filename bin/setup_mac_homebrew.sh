#!/bin/bash

# Homebrew セットアップスクリプト

set -e

#=============================
# Homebrew インストール
#=============================
brew -v || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew update
brew upgrade

#=============================
# Basic tools
#=============================
brew install zsh
mkdir -p ~/.zsh/
brew install bat
brew install coreutils
brew install fzf
brew install ghq
brew install go
brew install htop
brew install ipcalc
brew install jq
brew install yq
brew install nkf
brew install neovim
brew install tcptraceroute
brew install trash
brew install tree
brew install watch
brew install wget
brew install ripgrep
brew install sd
brew install ghostty
brew install powerlevel10k
brew install lsd
brew install atuin

#=============================
# Git tools
#=============================
brew install gh
brew install gist
brew install tig

#=============================
# DevOps tools
#=============================
brew install envchain
brew install tmux
brew install pyenv
brew install tfenv
brew install mise
brew install awscli

#=============================
# Kubernetes tools
#=============================
brew install eksctl
brew install kubent
brew install kubeseal
brew install krew
brew install kubecolor
brew install argocd

#=============================
# Container tools
#=============================
brew install colima docker docker-buildx docker-compose
brew install docker-credential-helper

#=============================
# krew plugins
#=============================
kubectl krew install resource-capacity
kubectl krew install score
kubectl krew install sniff
kubectl krew install stern
kubectl krew install tree
kubectl krew install neat
kubectl krew install rolesum

brew cleanup

echo "Done!"
