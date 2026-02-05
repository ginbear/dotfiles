# dotfiles

Personal dotfiles for macOS, managed with [chezmoi](https://www.chezmoi.io/).

## Setup

```bash
# 1. Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# 2. Clone with ghq
ghq get ginbear/dotfiles

# 3. Link chezmoi source to ghq repo
rm -rf ~/.local/share/chezmoi
ln -s ~/ghq/github.com/ginbear/dotfiles ~/.local/share/chezmoi

# 4. Apply dotfiles
chezmoi apply

# 5. Install Homebrew packages
sh bin/setup_mac_homebrew.sh
```

## Workflow

```bash
# 1. Edit in ghq repo
cd ~/ghq/github.com/ginbear/dotfiles
vim dot_zshrc

# 2. Apply and verify locally
chezmoi apply

# 3. Commit and push after verification
git add -A && git commit -m "..." && git push
```

## Update (on other machines)

```bash
chezmoi update   # git pull + apply
```

