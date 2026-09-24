#!/bin/bash
# Prevent commits on protected branches, block staging of sensitive files,
# and enforce development workflows (ghq, etc.)
#
# Protected branch names are read from ~/.claude/protected-branches (one per line).
# Create that file locally to enable branch protection.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$HOOK_CWD" ]] && HOOK_CWD="$PWD"

# 変数は同一コマンド内の代入からのみ解決する。cwd で代用すると別リポジトリに非公開 org 扱いを誤って与えかねない。
resolve_target_dir() {
  local raw="$1" cmd="$2" cwd="$3" name val pattern

  if [[ "$raw" =~ ^\"(.*)\"$ || "$raw" =~ ^\'(.*)\'$ ]]; then
    raw="${BASH_REMATCH[1]}"
  fi

  if [[ "$raw" =~ ^\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?(/.*)?$ ]]; then
    name="${BASH_REMATCH[1]}"
    local suffix="${BASH_REMATCH[2]}"
    if [[ "$name" == "HOME" ]]; then
      raw="${HOME}${suffix}"
    else
      pattern="(^|[;&|]|[[:space:]])[[:space:]]*(export[[:space:]]+)?${name}=(\"[^\"]*\"|'[^']*'|[^[:space:];&|]+)"
      if [[ "$cmd" =~ $pattern ]]; then
        val="${BASH_REMATCH[3]}"
        if [[ "$val" =~ ^\"(.*)\"$ || "$val" =~ ^\'(.*)\'$ ]]; then
          val="${BASH_REMATCH[1]}"
        fi
        raw="${val}${suffix}"
      fi
    fi
  fi

  [[ "$raw" == *'$'* ]] && return 1
  [[ "$raw" == "~"* ]] && raw="${HOME}${raw#\~}"
  [[ "$raw" != /* ]] && raw="${cwd%/}/${raw}"
  [[ -d "$raw" ]] || return 1

  printf '%s' "$raw"
}

NL=$'\n'

# heredoc 本文（-m "$(cat <<EOF ... EOF)" 等）はコミットメッセージの地の文なので、走査対象から除く。
strip_heredoc_bodies() {
  local cmd="$1" line delim="" out="" start_re="(^|[^<])<<-?[[:space:]]*[\"']?([A-Za-z_][A-Za-z0-9_]*)"
  while IFS= read -r line; do
    if [[ -n "$delim" ]]; then
      [[ "${line//[[:space:]]/}" == "$delim" ]] && delim=""
      continue
    fi
    out="${out}${line}${NL}"
    [[ "$line" =~ $start_re ]] && delim="${BASH_REMATCH[2]}"
  done <<< "$cmd"
  printf '%s' "$out"
}
SCAN_CMD=$(strip_heredoc_bodies "$COMMAND")

# git -C / cd は区切り文字（行頭・; & | (・改行）の直後に来た場合のみ拾う。commit メッセージ中の地の文と誤認しないため。
RAW_TARGET=""
if [[ "$SCAN_CMD" =~ (^|[\;\&\|\(]|${NL})[[:space:]]*git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
  RAW_TARGET="${BASH_REMATCH[2]}"
elif [[ "$SCAN_CMD" =~ (^|[\;\&\|\(]|${NL})[[:space:]]*cd[[:space:]]+([^[:space:];&]+) ]]; then
  RAW_TARGET="${BASH_REMATCH[2]}"
fi

# -C/cd 指定なし = cwd がそのまま対象。指定はあるが解決不能、は cwd で代用してよい根拠が無い（別ケース）。
REPO_UNRESOLVED=0
if [[ -z "$RAW_TARGET" ]]; then
  TARGET_DIR="$HOOK_CWD"
elif RESOLVED=$(resolve_target_dir "$RAW_TARGET" "$SCAN_CMD" "$HOOK_CWD"); then
  TARGET_DIR="$RESOLVED"
else
  REPO_UNRESOLVED=1
  TARGET_DIR="/nonexistent-org-term-scan-target"
fi

UNRESOLVED_MSG="コミット/push 対象のリポジトリを解決できませんでした（-C/cd の指定先 '${RAW_TARGET}' をこのコマンド内で解決できません）。安全側でブロックします。実パスを指定するか、同じコマンド内で変数を代入してから実行してください。"

# "git -C <path> commit" は "git commit" に一致しないので、部分一致の前に -C を畳む。
NORMALIZED=$(printf '%s' "$COMMAND" | sed -E 's#git[[:space:]]+-C[[:space:]]+[^[:space:]]+[[:space:]]+#git #g')

# Check 1: Block git commit on protected branches
CONFIG="$HOME/.claude/protected-branches"
if [[ "$NORMALIZED" == *"git commit"* ]] && [[ -f "$CONFIG" ]]; then
  if [[ $REPO_UNRESOLVED -eq 1 ]]; then
    echo "BLOCKED: $UNRESOLVED_MSG" >&2
    exit 2
  fi
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
    # 未解決時は $TARGET_DIR がダミーパスなので、org-term-scan 側の非公開 org 判定は必ず失敗し無条件でスキャンされる。
    if ! HITS=$(printf '%s' "$COMMAND" | org-term-scan --text --repo "$TARGET_DIR" 2>&1); then
      echo "BLOCKED: $HITS" >&2
      if [[ $REPO_UNRESOLVED -eq 1 ]]; then
        echo "" >&2
        echo "HINT: -C/cd の指定先 '${RAW_TARGET}' を解決できなかったため、非公開 org の除外なしで検査しました。実パスを指定するか、同じコマンド内で変数を代入してから実行してください。" >&2
      fi
      exit 2
    fi
  fi

  # 手を離れる最後の関門。既に履歴にある混入は commit 時には見えないのでここで止める。
  if [[ "$NORMALIZED" == *"git push"* ]]; then
    if [[ $REPO_UNRESOLVED -eq 1 ]]; then
      echo "BLOCKED: $UNRESOLVED_MSG" >&2
      exit 2
    fi
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
