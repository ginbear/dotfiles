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
# パッケージリスト
#=============================
BASIC_TOOLS=(
  zsh
  bat
  coreutils
  fzf
  ghq
  go
  ipcalc
  jq
  yq
  nkf
  neovim
  tcptraceroute
  tree
  watch
  wget
  ripgrep
  sd
  ghostty
  powerlevel10k
  lsd
  atuin
  navi
  zellij
)

GIT_TOOLS=(
  gh
  gist
  tig
)

DEVOPS_TOOLS=(
  envchain
  tmux
  pyenv
  tfenv
  mise
  awscli
  chezmoi
)

K8S_TOOLS=(
  eksctl
  kubent
  kubeseal
  krew
  kubecolor
  argocd
)

CONTAINER_TOOLS=(
  colima
  docker
  docker-buildx
  docker-compose
  docker-credential-helper
)

KREW_PLUGINS=(
  resource-capacity
  score
  sniff
  stern
  tree
  neat
  rolesum
)

CASK_APPS=(
  visual-studio-code
  cmd-eikana
  the-unarchiver
  kindle
  keyboardcleantool
)

#=============================
# インストール関数
#=============================
install_packages() {
  local label="$1"
  shift
  local packages=("$@")

  echo "Installing $label..."
  for pkg in "${packages[@]}"; do
    brew install "$pkg" || echo "  Warning: $pkg failed"
  done
}

install_casks() {
  echo "Installing Cask apps..."
  for app in "${CASK_APPS[@]}"; do
    brew install --cask "$app" || echo "  Warning: $app failed"
  done
}

install_krew_plugins() {
  echo "Installing krew plugins..."
  for plugin in "${KREW_PLUGINS[@]}"; do
    kubectl krew install "$plugin" || echo "  Warning: $plugin failed"
  done
}

#=============================
# メイン
#=============================
mkdir -p ~/.zsh/

install_packages "Basic tools" "${BASIC_TOOLS[@]}"
install_packages "Git tools" "${GIT_TOOLS[@]}"
install_packages "DevOps tools" "${DEVOPS_TOOLS[@]}"
install_packages "Kubernetes tools" "${K8S_TOOLS[@]}"
install_packages "Container tools" "${CONTAINER_TOOLS[@]}"
install_casks
install_krew_plugins

brew cleanup

echo "Done!"
