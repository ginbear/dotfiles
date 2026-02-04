#!/bin/bash
# Claude Code Statusline Script (Rich version with Nerd Fonts)
# Displays: Model, Directory, Git Branch, Context Usage, Cost

input=$(cat)

# ─────────────────────────────────────────────────────────────
# Nerd Fonts Icons (UTF-8 hex bytes for bash 3.x compatibility)
# ─────────────────────────────────────────────────────────────
ICON_MODEL=$(printf "\xf3\xb0\x9a\xa9")  # U+F06A9 nf-md-assistant
ICON_DIR=$(printf "\xef\x90\x93")        # U+F413 nf-oct-file_directory
ICON_GIT=$(printf "\xee\x82\xa0")        # U+E0A0 nf-dev-git_branch
ICON_CONTEXT=$(printf "\xef\x83\xa4")    # U+F0E4 nf-fa-tachometer
ICON_COST=$(printf "\xef\x85\x95")       # U+F155 nf-fa-dollar

# ─────────────────────────────────────────────────────────────
# Extract values using jq
# ─────────────────────────────────────────────────────────────
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // "/"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Context window usage
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq '.context_window.current_usage // empty')

# ─────────────────────────────────────────────────────────────
# Format directory (show last component)
# ─────────────────────────────────────────────────────────────
DIR_NAME="${CURRENT_DIR##*/}"
[ -z "$DIR_NAME" ] && DIR_NAME="/"

# ─────────────────────────────────────────────────────────────
# Git branch
# ─────────────────────────────────────────────────────────────
GIT_BRANCH=""
if git -C "$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$CURRENT_DIR" branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        GIT_BRANCH=" ${ICON_GIT} ${BRANCH}"
    fi
fi

# ─────────────────────────────────────────────────────────────
# Context usage percentage
# ─────────────────────────────────────────────────────────────
if [ -n "$USAGE" ] && [ "$USAGE" != "null" ]; then
    TOKENS=$(echo "$USAGE" | jq '(.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)')
    PCT=$((TOKENS * 100 / CTX_SIZE))
else
    PCT=0
fi

# ─────────────────────────────────────────────────────────────
# Format cost
# ─────────────────────────────────────────────────────────────
if [ "$COST" = "0" ] || [ "$COST" = "null" ]; then
    COST_STR="0.00"
else
    COST_STR=$(echo "$COST" | awk '{
        if ($1 < 0.01) {
            printf "%.4f", $1
        } else {
            printf "%.2f", $1
        }
    }')
fi

# ─────────────────────────────────────────────────────────────
# Output (no ANSI colors for maximum compatibility)
# ─────────────────────────────────────────────────────────────
echo "${ICON_MODEL} ${MODEL}  ${ICON_DIR} ${DIR_NAME}${GIT_BRANCH}  ${ICON_CONTEXT} ${PCT}%  ${ICON_COST}${COST_STR}"
