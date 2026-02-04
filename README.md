# dotfiles

Personal dotfiles for macOS, managed with [chezmoi](https://www.chezmoi.io/).

## Setup

```bash
# 1. Install chezmoi and initialize
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ginbear

# 2. Install Homebrew packages
sh bin/setup_mac_homebrew.sh
```

## Update

```bash
chezmoi update   # git pull + external repos + apply
```

## Workflow

```bash
# 1. Edit in ghq repo
cd ~/ghq/github.com/ginbear/dotfiles
vim dot_zshrc

# 2. Commit and push
git add -A && git commit -m "..." && git push

# 3. Apply changes
chezmoi update
```

## Legacy

以前のsymlink方式から移行済み。`bin/init.sh` は参考用に残存。
