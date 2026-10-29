#!/bin/bash
# 運用ルールのうち人の注意に頼っていたものを PreToolUse / Bash で止める。
# deny: terraform/terragrunt/tofu の -auto-approve、PR のマージ（gh pr merge / merge API）
# ask:  force push、gh の本文に入った @メンション、prd（または環境不明）への kubectl 書き込み

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
HOOK_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0
[[ -z "$HOOK_CWD" ]] && HOOK_CWD="$PWD"

NL=$'\n'

# heredoc 本文は走査から除く（PR 本文中の「gh pr merge」等で誤爆させない）。bash/sh/eval 等へ流し込む本文は実行されるので残す。
strip_heredoc_bodies() {
  local cmd="$1" line delim="" out="" keep=0
  local start_re="(^|[^<])<<-?[[:space:]]*[\"']?([A-Za-z_][A-Za-z0-9_]*)"
  local shell_re="(^|[^[:alnum:]_])(bash|sh|zsh|eval|source|xargs)([^[:alnum:]_]|$)"
  while IFS= read -r line; do
    if [[ -n "$delim" ]]; then
      if [[ "${line//[[:space:]]/}" == "$delim" ]]; then
        delim=""; keep=0
        out="${out}${line}${NL}"
      elif (( keep )); then
        out="${out}${line}${NL}"
      fi
      continue
    fi
    out="${out}${line}${NL}"
    if [[ "$line" =~ $start_re ]]; then
      delim="${BASH_REMATCH[2]}"
      if [[ "$line" =~ $shell_re ]]; then keep=1; else keep=0; fi
    fi
  done <<< "$cmd"
  printf '%s' "$out"
}

# 行継続を畳んでから走査する。`gh pr merge \` + 改行 + `--squash` のような分割をすり抜けさせないため。
SCAN=$(strip_heredoc_bodies "$COMMAND")
SCAN="${SCAN//\\${NL}/ }"

SEG="[^;&|${NL}]*"
START="(^|[^[:alnum:]_./-])"
SHOWN="${COMMAND:0:300}"

emit() {
  jq -n --arg d "$1" --arg r "$2" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

# --- deny ---

if [[ "$SCAN" =~ ${START}(terraform|terragrunt|tofu)${SEG}[[:space:]]--?auto-approve ]] \
  || [[ "$SCAN" =~ TF_CLI_ARGS[A-Za-z_]*=${SEG}auto-approve ]]; then
  emit deny "[workflow-guard] -auto-approve は禁止。plan -out=<file> → レビュー → apply <file> で進める（/terraform-apply skill）。"
fi

if [[ "$SCAN" =~ ${START}gh${SEG}[[:space:]]pr[[:space:]]+merge([[:space:]]|$) ]] \
  || [[ "$SCAN" =~ ${START}gh[[:space:]]+api${SEG}pulls/[^[:space:]/]+/merge([[:space:]\"\']|$) ]]; then
  emit deny "[workflow-guard] PR のマージは人間が行う（squash も禁止）。マージ可能になったことを報告して止まる。"
fi

# --- ask ---

REASONS=()

push_re="${START}git${SEG}[[:space:]]push${SEG}[[:space:]](--force|--force-with-lease|--force-if-includes|-[A-Za-z]*f[A-Za-z]*|\+[^[:space:]]+)([=[:space:]]|$)"
if [[ "$SCAN" =~ $push_re ]]; then
  REASONS+=("force push はレビュー中の履歴を書き換える。事前にユーザーの確認が必須。")
fi

# 本文は heredoc や --body-file にあるので、メンションだけは元のコマンドと本文ファイルを走査する。
gh_body_re="${START}gh[[:space:]]+((pr|issue)[[:space:]]+(create|edit|comment|review)|api)([[:space:]]|$)"
if [[ "$COMMAND" =~ $gh_body_re ]]; then
  # --jq / -q の式（`@tsv` 等）は本文ではないので除く。
  BODY="$COMMAND"
  jq_re="(^|[[:space:]])(--jq|-q)[=[:space:]]+('[^']*'|\"[^\"]*\"|[^[:space:]]+)"
  while [[ "$BODY" =~ $jq_re ]]; do BODY="${BODY/"${BASH_REMATCH[0]}"/ }"; done
  file_re="(--body-file|-F)[=[:space:]]+[\"']?([^[:space:]\"']+)"
  rest="$COMMAND"
  while [[ "$rest" =~ $file_re ]]; do
    f="${BASH_REMATCH[2]#*=@}"; f="${f#@}"
    [[ "$f" == "~"* ]] && f="${HOME}${f#\~}"
    [[ "$f" != /* ]] && f="${HOOK_CWD%/}/${f}"
    [[ -f "$f" ]] && BODY="${BODY}${NL}$(cat "$f")"
    rest="${rest#*"${BASH_REMATCH[0]}"}"
  done
  # メール・action@v4・body=@file・@{u} は前後の文字で除外する。
  mention_re="(^|[^[:alnum:]_.=/@-])@([A-Za-z0-9][A-Za-z0-9-]*(/[A-Za-z0-9._-]+)?)"
  if [[ "$BODY" =~ $mention_re ]]; then
    REASONS+=("GitHub に書く本文に @${BASH_REMATCH[2]} がある。メンションは通知が飛ぶので人間が行う。外すか、意図したものかユーザーに確認する。")
  fi
fi

kube_write_re="${START}kubectl${SEG}[[:space:]](apply|create|delete|patch|edit|replace|scale|label|annotate|set|drain|cordon|uncordon|taint|rollout[[:space:]]+(restart|undo|pause|resume))([[:space:]]|$)"
if [[ "$SCAN" =~ $kube_write_re ]] && ! [[ "$SCAN" =~ --dry-run(=|[[:space:]]+)(client|server) ]]; then
  VERB="${BASH_REMATCH[2]}"
  # 環境は -prd/-stg/-dev（_ 区切りも可）で終わる名前から判定する（kube-exec-guard.sh と同じ規則）。
  if   [[ "$SCAN" =~ [-_]prd([^[:alnum:]]|$) ]]; then ENV_NAME=prd
  elif [[ "$SCAN" =~ [-_](stg|dev)([^[:alnum:]]|$) || "$SCAN" =~ minikube ]]; then ENV_NAME=nonprd
  elif [[ "$SCAN" =~ --context([=[:space:]]) ]]; then ENV_NAME=unknown
  else
    CUR=$(kubectl config current-context 2>/dev/null)
    if   [[ "$CUR" =~ [-_]prd([^[:alnum:]]|$) ]]; then ENV_NAME=prd
    elif [[ "$CUR" =~ [-_](stg|dev)([^[:alnum:]]|$) || "$CUR" == minikube ]]; then ENV_NAME=nonprd
    else ENV_NAME=unknown
    fi
  fi
  case "$ENV_NAME" in
    prd)     REASONS+=("[prd] kubectl ${VERB}: prd への書き込みは実行前にユーザーの確認が必須。dev/stg や参照系で代替できないか先に検討する。") ;;
    unknown) REASONS+=("[環境不明] kubectl ${VERB}: 実行先を特定できないため prd として扱う。--context を明示する。") ;;
  esac
fi

if [[ ${#REASONS[@]} -gt 0 ]]; then
  emit ask "[workflow-guard] ${REASONS[*]} 実行内容: ${SHOWN}"
fi

exit 0
