#!/bin/bash
# Prevent commits on protected branches and block staging of local-only files
#
# Protected branch names are read from ~/.claude/protected-branches (one per line).
# Create that file locally to enable branch protection.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Check 1: Block git commit on protected branches
CONFIG="$HOME/.claude/protected-branches"
if [[ "$COMMAND" == *"git commit"* ]] && [[ -f "$CONFIG" ]]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    while IFS= read -r protected; do
      [[ -z "$protected" || "$protected" == \#* ]] && continue
      if [[ "$BRANCH" == "$protected" ]]; then
        echo "BLOCKED: Cannot commit directly on protected branch '$BRANCH'. Create a feature branch first." >&2
        exit 2
      fi
    done < "$CONFIG"
  fi
fi

# Check 2: Block git add of local-only files
if [[ "$COMMAND" == *"git add"* ]] && [[ "$COMMAND" == *"settings.local.json"* ]]; then
  echo "BLOCKED: settings.local.json should not be committed." >&2
  exit 2
fi

exit 0
