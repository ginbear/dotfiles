#!/bin/bash
# Prevent commits on protected branches, block staging of sensitive files,
# and enforce development workflows (ghq, etc.)
#
# Protected branch names are read from ~/.claude/protected-branches (one per line).
# Create that file locally to enable branch protection.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Check 1: Block git commit on protected branches
CONFIG="$HOME/.claude/protected-branches"
if [[ "$COMMAND" == *"git commit"* ]] && [[ -f "$CONFIG" ]]; then
  # Resolve target repo: support "git -C <path>" and "cd <path> && git commit"
  GIT_DIR_ARGS=()
  if [[ "$COMMAND" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
    GIT_DIR_ARGS=(-C "${BASH_REMATCH[1]}")
  elif [[ "$COMMAND" =~ cd[[:space:]]+([^[:space:];&]+) ]]; then
    GIT_DIR_ARGS=(-C "${BASH_REMATCH[1]}")
  fi
  BRANCH=$(git "${GIT_DIR_ARGS[@]}" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    while IFS= read -r protected; do
      [[ -z "$protected" || "$protected" == \#* ]] && continue
      if [[ "$BRANCH" == "$protected" ]]; then
        REPO_PATH="CWD"
        [[ ${#GIT_DIR_ARGS[@]} -gt 0 ]] && REPO_PATH="${GIT_DIR_ARGS[1]}"
        echo "BLOCKED: Cannot commit directly on protected branch '$BRANCH' ($REPO_PATH). Create a feature branch first." >&2
        exit 2
      fi
    done < "$CONFIG"
  fi
fi

# Check 2: Block git add of sensitive files
if [[ "$COMMAND" == *"git add"* ]]; then
  if [[ "$COMMAND" == *"settings.local.json"* ]]; then
    echo "BLOCKED: settings.local.json should not be committed." >&2
    exit 2
  fi
  if [[ "$COMMAND" == *".env"* ]]; then
    echo "BLOCKED: .env files should not be committed (contains secrets)." >&2
    exit 2
  fi
  if [[ "$COMMAND" == *".tfvars"* ]]; then
    echo "BLOCKED: .tfvars files should not be committed (contains secrets)." >&2
    exit 2
  fi
fi

# Check 3: Block git clone (use ghq get instead)
if [[ "$COMMAND" == *"git clone"* ]]; then
  echo "BLOCKED: git clone is not allowed. Use 'ghq get <repo>' instead." >&2
  exit 2
fi

exit 0
