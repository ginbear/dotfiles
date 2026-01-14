# dotfiles

Personal dotfiles for macOS.

## Setup

```bash
# 1. Clone repository
ghq get https://github.com/ginbear/dotfiles.git
cd $(ghq root)/github.com/ginbear/dotfiles

# 2. Create symlinks
sh bin/init.sh

# 3. Install Homebrew packages
sh bin/setup_mac_homebrew.sh
```

## Contents

| File/Directory | Description |
|----------------|-------------|
| `.zshrc` | Zsh configuration |
| `.shellrc` | Common shell settings (aliases, PATH, etc.) |
| `.p10k.zsh` | Powerlevel10k theme config |
| `.gitconfig` | Git configuration |
| `.config/ghostty/` | Ghostty terminal config |
| `.config/nvim/` | Neovim config |
| `.claude/` | Claude Code settings |
| `bin/init.sh` | Symlink setup script |
| `bin/setup_mac_homebrew.sh` | Homebrew packages installer |
