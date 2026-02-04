#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
TEAM_DIR="$CLAUDE_DIR/team/dot_claude"
PERSONAL_DIR="$CLAUDE_DIR/personal"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SKILLS_DIR="$CLAUDE_DIR/skills"

mkdir -p "$COMMANDS_DIR" "$SKILLS_DIR"

# Team commands
if [ -d "$TEAM_DIR/commands" ]; then
    for file in "$TEAM_DIR/commands"/*.md; do
        [ -f "$file" ] && ln -sf "$file" "$COMMANDS_DIR/"
    done
fi

# Team skills
if [ -d "$TEAM_DIR/skills" ]; then
    for dir in "$TEAM_DIR/skills"/*/; do
        [ -d "$dir" ] && ln -sf "$dir" "$SKILLS_DIR/"
    done
fi

# Personal commands
if [ -d "$PERSONAL_DIR/commands" ]; then
    for file in "$PERSONAL_DIR/commands"/*.md; do
        [ -f "$file" ] && ln -sf "$file" "$COMMANDS_DIR/"
    done
fi

# Personal skills
if [ -d "$PERSONAL_DIR/skills" ]; then
    for dir in "$PERSONAL_DIR/skills"/*/; do
        [ -d "$dir" ] && ln -sf "$dir" "$SKILLS_DIR/"
    done
fi

echo "[OK] Claude commands/skills merged"

# Copy secrets from ghq dotfiles (not tracked in git)
DOTFILES_GHQ="$HOME/ghq/github.com/ginbear/dotfiles"
if [ -d "$DOTFILES_GHQ" ]; then
    # gh hosts.yml
    if [ -f "$DOTFILES_GHQ/dot_config/gh/hosts.yml" ]; then
        mkdir -p "$HOME/.config/gh"
        cp "$DOTFILES_GHQ/dot_config/gh/hosts.yml" "$HOME/.config/gh/"
    fi
    # raycast
    if [ -d "$DOTFILES_GHQ/dot_config/raycast" ]; then
        rm -rf "$HOME/.config/raycast"
        cp -r "$DOTFILES_GHQ/dot_config/raycast" "$HOME/.config/"
    fi
    # karabiner
    if [ -d "$DOTFILES_GHQ/dot_config/karabiner" ]; then
        rm -rf "$HOME/.config/karabiner"
        cp -r "$DOTFILES_GHQ/dot_config/karabiner" "$HOME/.config/"
    fi
    echo "[OK] Secrets copied from ghq dotfiles"
fi
