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
# コマンド形の検査は heredoc 本文を除いた版で行う。コミットメッセージ中の例示で誤爆させないため。
SCAN_NORM=$(printf '%s' "$SCAN_CMD" | sed -E 's#git[[:space:]]+-C[[:space:]]+[^[:space:]]+[[:space:]]+#git #g')
CMD_START="(^|[;&|(]|${NL})[[:space:]]*"

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
if [[ "$SCAN_NORM" == *"git add"* ]]; then
  if [[ "$SCAN_NORM" == *"settings.local.json"* ]]; then
    echo "BLOCKED: settings.local.json should not be committed." >&2
    exit 2
  fi
  if [[ "$SCAN_NORM" == *".env"* ]]; then
    echo "BLOCKED: .env files should not be committed (contains secrets)." >&2
    exit 2
  fi
  if [[ "$SCAN_NORM" == *".tfvars"* ]]; then
    echo "BLOCKED: .tfvars files should not be committed (contains secrets)." >&2
    exit 2
  fi
fi

# Check 3: Block git clone (use ghq get instead)
if [[ "$SCAN_NORM" == *"git clone"* ]]; then
  echo "BLOCKED: git clone is not allowed. Use 'ghq get <repo>' instead." >&2
  exit 2
fi

# gh の --repo/-R は対象リポジトリを cd 先より強く決めるので、そちらを非公開 org 判定に使う。
# 引用符付きの本文（-b "..." 等）に書かれた --repo を拾わないよう、値を外した後で残りの引用符付き文字列を捨てる。
GH_REPO_SLUGS=()
GH_TRIGGERS=0
GH_UNANCHORED=0
# gh 本体ではなくサブコマンド列で引っ掛ける。絶対パス起動を取りこぼすと未検査のまま素通りするため。
GH_SUBCMD_RE='(^|[[:space:]])(pr|issue|release)[[:space:]]+(create|edit|comment)([[:space:]]|$)'
collect_gh_repo_slugs() {
  local cmd="$1" seg val nflags
  cmd=$(printf '%s' "$cmd" | sed -E "s/(--repo|-R)([[:space:]]+|=)\"([^\"]*)\"/\1 \3/g; s/(--repo|-R)([[:space:]]+|=)'([^']*)'/\1 \3/g")
  cmd=$(printf '%s' "$cmd" | sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g")
  while IFS= read -r seg; do
    seg="${seg#"${seg%%[![:space:]]*}"}"
    [[ "$seg" =~ $GH_SUBCMD_RE ]] || continue
    # 行頭の素の gh 以外（env 前置・絶対パス・xargs 等）は引数の対応が取れないので、cd 先での検査に落とす。
    if [[ ! "$seg" =~ ^gh[[:space:]] ]]; then
      GH_UNANCHORED=1
      continue
    fi
    GH_TRIGGERS=$((GH_TRIGGERS + 1))
    val=""
    if [[ "$seg" =~ (^|[[:space:]])--repo[=[:space:]][[:space:]]*([^[:space:]]+) ]]; then
      val="${BASH_REMATCH[2]}"
    elif [[ "$seg" =~ (^|[[:space:]])-R=?[[:space:]]*([^[:space:]]+) ]]; then
      val="${BASH_REMATCH[2]}"
    fi
    [[ -z "$val" ]] && continue
    # gh は重複フラグの最後の値を採るが、ここでは最初しか見ない。重複時は判定に使わず必ず検査させる。
    nflags=$(printf '%s' "$seg" | grep -o -E '(^|[[:space:]])(--repo[=[:space:]]|-R)' | wc -l | tr -d '[:space:]')
    [[ "$nflags" -gt 1 ]] && val=""
    # 変数展開などで静的に解決できない値は、非公開 org 判定に使わず必ず検査させる。
    [[ "$val" =~ [^A-Za-z0-9._/-] ]] && val=""
    GH_REPO_SLUGS+=("$val")
  done < <(printf '%s\n' "$cmd" | tr ';&|()' $'\n\n\n\n\n')
}

# Check 4: Block org / internal repo names reaching a public repo.
if command -v org-term-scan >/dev/null 2>&1; then
  # pre-commit only sees staged files, so the PR body and issue comments are covered here.
  if [[ "$NORMALIZED" == *"git commit"* \
     || "$NORMALIZED" == *"gh pr create"*  || "$NORMALIZED" == *"gh pr edit"* \
     || "$NORMALIZED" == *"gh pr comment"* || "$NORMALIZED" == *"gh issue create"* \
     || "$NORMALIZED" == *"gh issue edit"* || "$NORMALIZED" == *"gh issue comment"* \
     || "$NORMALIZED" == *"gh release create"* ]]; then
    collect_gh_repo_slugs "$SCAN_CMD"

    # 対象ごとに1回ずつ検査し、1つでも引っかかればブロックする。全ての対象が非公開 org のときだけ素通りする。
    DIR_SCAN=1
    if [[ $GH_TRIGGERS -gt 0 && $GH_UNANCHORED -eq 0 \
       && ${#GH_REPO_SLUGS[@]} -eq $GH_TRIGGERS \
       && "$NORMALIZED" != *"git commit"* ]]; then
      DIR_SCAN=0
    fi

    for SLUG in ${GH_REPO_SLUGS[@]+"${GH_REPO_SLUGS[@]}"}; do
      if ! HITS=$(printf '%s' "$COMMAND" | org-term-scan --text --repo-slug "$SLUG" 2>&1); then
        echo "BLOCKED: $HITS" >&2
        exit 2
      fi
    done

    # 未解決時は $TARGET_DIR がダミーパスなので、org-term-scan 側の非公開 org 判定は必ず失敗し無条件でスキャンされる。
    if [[ $DIR_SCAN -eq 1 ]]; then
      if ! HITS=$(printf '%s' "$COMMAND" | org-term-scan --text --repo "$TARGET_DIR" 2>&1); then
        echo "BLOCKED: $HITS" >&2
        if [[ $REPO_UNRESOLVED -eq 1 ]]; then
          echo "" >&2
          echo "HINT: -C/cd の指定先 '${RAW_TARGET}' を解決できなかったため、非公開 org の除外なしで検査しました。実パスを指定するか、同じコマンド内で変数を代入してから実行してください。" >&2
        fi
        exit 2
      fi
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

# Check 5: Block staging everything at once
if [[ "$SCAN_NORM" =~ ${CMD_START}git[[:space:]]+add([[:space:]]+[^[:space:]\;\&\|]+)*[[:space:]]+(\.|-A|--all|:/)([[:space:]\;\&\|\)]|$) ]]; then
  echo "BLOCKED: git add -A / git add . is not allowed. Stage files by path." >&2
  exit 2
fi

# Check 6: Block in-place rewrites and interpreter heredocs (use Edit / Write)
if [[ "$SCAN_NORM" =~ ${CMD_START}(xargs[[:space:]]+)?(sed|perl)([[:space:]]+-[^[:space:]]*)*[[:space:]]+(-[a-zA-Z]*i[a-zA-Z]*|--in-place) ]]; then
  echo "BLOCKED: in-place rewrite (sed -i / perl -i) is not allowed. Use the Edit / Write tools." >&2
  exit 2
fi
if [[ "$SCAN_NORM" =~ ${CMD_START}(python3?|ruby|perl|node)([[:space:]]+-)?[[:space:]]*\<\< ]]; then
  echo "BLOCKED: interpreter heredoc is not allowed. File edits: use Edit / Write. Read-only parsing: use a one-liner (python3 -c / jq)." >&2
  exit 2
fi

# Check 7: Block commits with unformatted Terragrunt HCL
if [[ "$SCAN_NORM" == *"git commit"* ]]; then
  if [[ $REPO_UNRESOLVED -eq 1 ]]; then
    echo "BLOCKED: $UNRESOLVED_MSG" >&2
    exit 2
  fi
  ROOT=$(git -C "$TARGET_DIR" rev-parse --show-toplevel 2>/dev/null)
  # 同じコマンド内で git add される前に呼ばれるため、staged に限らず作業ツリーの変更を対象にする。
  HCL_FILES=()
  if [ -n "$ROOT" ]; then
    while IFS= read -r f; do
      [[ -n "$f" && "${f##*/}" != ".terraform.lock.hcl" ]] && HCL_FILES+=("$f")
    done < <({ git -C "$ROOT" diff --name-only --diff-filter=d HEAD -- '*.hcl'; git -C "$ROOT" ls-files --others --exclude-standard -- '*.hcl'; } 2>/dev/null | sort -u)
  fi
  # pre-commit と同じく、terragrunt を解決できない環境では黙って通す。
  if [ ${#HCL_FILES[@]} -gt 0 ] && command -v mise >/dev/null 2>&1 && mise -C "$ROOT" which terragrunt >/dev/null 2>&1; then
    UNFORMATTED=()
    for f in "${HCL_FILES[@]}"; do
      mise -C "$ROOT" exec -- terragrunt hcl fmt --check --file "$ROOT/$f" >/dev/null 2>&1 || UNFORMATTED+=("$f")
    done
    if [ ${#UNFORMATTED[@]} -gt 0 ]; then
      echo "BLOCKED: unformatted HCL in $ROOT: ${UNFORMATTED[*]}" >&2
      echo "Run 'terragrunt hcl fmt --file <path>' for each file, then commit again." >&2
      exit 2
    fi
  fi
fi

exit 0
