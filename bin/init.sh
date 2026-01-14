#!/bin/bash

# dotfiles セットアップスクリプト
# Usage: ghq get して sh bin/init.sh を実行

set -e

DOTFILES_DIR="${PWD}"

#=============================
# シンボリックリンクを作成するファイル
#=============================
DOTFILES="
.gitignore
.gitconfig
.shellrc
.zshrc
.p10k.zsh
.snippets
.tmux.conf
.config
"

CLAUDE_FILES="
settings.json
CLAUDE.md
"

#=============================
# バックアップ
#=============================
backup_existing() {
  local backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
  local need_backup=false

  for file in ${DOTFILES}; do
    if [[ -e "$HOME/$file" && ! -L "$HOME/$file" ]]; then
      need_backup=true
      break
    fi
  done

  if $need_backup; then
    echo "Backing up existing files to $backup_dir"
    mkdir -p "$backup_dir"
    for file in ${DOTFILES}; do
      if [[ -e "$HOME/$file" && ! -L "$HOME/$file" ]]; then
        mv "$HOME/$file" "$backup_dir/"
      fi
    done
  fi
}

#=============================
# シンボリックリンク作成
#=============================
create_symlinks() {
  echo "Creating symlinks..."

  for file in ${DOTFILES}; do
    rm -rf "$HOME/$file"
    ln -s "$DOTFILES_DIR/$file" "$HOME/$file"
    echo "  $file -> $DOTFILES_DIR/$file"
  done
}

create_claude_symlinks() {
  echo "Creating Claude symlinks..."
  mkdir -p "$HOME/.claude"

  for file in ${CLAUDE_FILES}; do
    rm -rf "$HOME/.claude/$file"
    ln -s "$DOTFILES_DIR/.claude/$file" "$HOME/.claude/$file"
    echo "  .claude/$file -> $DOTFILES_DIR/.claude/$file"
  done
}

#=============================
# メイン
#=============================
main() {
  echo "=== dotfiles setup ==="
  echo "DOTFILES_DIR: $DOTFILES_DIR"
  echo ""

  backup_existing
  create_symlinks
  create_claude_symlinks

  echo ""
  echo "Done!"
}

main
