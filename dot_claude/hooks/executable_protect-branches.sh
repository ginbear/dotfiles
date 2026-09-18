#!/bin/bash
# Prevent commits on protected branches, block staging of sensitive files,
# and enforce development workflows (ghq, etc.)
#
# Protected branch names are read from ~/.claude/protected-branches (one per line).
# Create that file locally to enable branch protection.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Resolve target repo: support "git -C <path>" and "cd <path> && ..."
TARGET_DIR="."
if [[ "$COMMAND" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
  TARGET_DIR="${BASH_REMATCH[1]}"
elif [[ "$COMMAND" =~ cd[[:space:]]+([^[:space:];&]+) ]]; then
  TARGET_DIR="${BASH_REMATCH[1]}"
fi

# "git -C <path> commit" は "git commit" に一致しないので、部分一致の前に -C を畳む。
NORMALIZED=$(printf '%s' "$COMMAND" | sed -E 's#git[[:space:]]+-C[[:space:]]+[^[:space:]]+[[:space:]]+#git #g')

# Check 1: Block git commit on protected branches
CONFIG="$HOME/.claude/protected-branches"
if [[ "$NORMALIZED" == *"git commit"* ]] && [[ -f "$CONFIG" ]]; then
  BRANCH=$(git -C "$TARGET_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    while IFS= read -r protected; do
      [[ -z "$protected" || "$protected" == \#* ]] && continue
      if [[ "$BRANCH" == "$protected" ]]; then
        echo "BLOCKED: Cannot commit directly on protected branch '$BRANCH' ($TARGET_DIR). Create a feature branch first." >&2
        exit 2
      fi
    done < "$CONFIG"
  fi
fi

# Check 2: Block git add of sensitive files
if [[ "$NORMALIZED" == *"git add"* ]]; then
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
if [[ "$NORMALIZED" == *"git clone"* ]]; then
  echo "BLOCKED: git clone is not allowed. Use 'ghq get <repo>' instead." >&2
  exit 2
fi

# Check 4: Block org / internal repo names reaching a public repo.
if command -v org-term-scan >/dev/null 2>&1; then
  # pre-commit only sees staged files, so the PR body and issue comments are covered here.
  if [[ "$NORMALIZED" == *"git commit"* \
     || "$NORMALIZED" == *"gh pr create"*  || "$NORMALIZED" == *"gh pr edit"* \
     || "$NORMALIZED" == *"gh pr comment"* || "$NORMALIZED" == *"gh issue create"* \
     || "$NORMALIZED" == *"gh issue edit"* || "$NORMALIZED" == *"gh issue comment"* \
     || "$NORMALIZED" == *"gh release create"* ]]; then
    if ! HITS=$(printf '%s' "$COMMAND" | org-term-scan --text --repo "$TARGET_DIR" 2>&1); then
      echo "BLOCKED: $HITS" >&2
      exit 2
    fi
  fi

  # 手を離れる最後の関門。既に履歴にある混入は commit 時には見えないのでここで止める。
  if [[ "$NORMALIZED" == *"git push"* ]]; then
    ROOT=$(git -C "$TARGET_DIR" rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$ROOT" ]; then
      BASE=$(git -C "$ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
      [ -z "$BASE" ] && BASE=$(git -C "$ROOT" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
      PUSH_FILES=()
      if [ -n "$BASE" ]; then
        while IFS= read -r f; do
          [ -n "$f" ] && PUSH_FILES+=("$ROOT/$f")
        done < <(git -C "$ROOT" diff --name-only --diff-filter=d "$BASE...HEAD" 2>/dev/null)
      fi
      if [ ${#PUSH_FILES[@]} -gt 0 ]; then
        if ! HITS=$(org-term-scan --files --repo "$ROOT" "${PUSH_FILES[@]}" 2>&1); then
          echo "BLOCKED: $HITS" >&2
          exit 2
        fi
      fi
    fi
  fi
fi

exit 0
