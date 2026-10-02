#!/bin/bash
# kubectl exec/debug/cp/attach と aws ecs execute-command / ssm start-session を検出し、実行前に人間の確認を必須にする (PreToolUse / Bash)。
# どの環境でも ask にし、環境名を理由に出す。判定できない場合も ask に倒す。

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

NL=$'\n'

# heredoc 本文（PR 説明やコミットメッセージ等）は走査から除く。ただし bash/sh/eval 等へ流し込む本文は実行されるので残す。
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

SCAN=$(strip_heredoc_bodies "$COMMAND")

# kubectl と動詞は同一セグメント（; & | 改行で区切る）に限る。`kubectl kustomize x && cp a b` を拾わないため。
kube_re="(^|[^[:alnum:]_./-])kubectl[^;&|${NL}]*[[:space:]](exec|debug|cp|attach)([[:space:]]|\$)"
aws_re="(^|[^[:alnum:]_./-])aws[[:space:]]+(ecs[[:space:]]+execute-command|ssm[[:space:]]+start-session)([[:space:]]|\$)"

KIND=""
if [[ "$SCAN" =~ $kube_re ]]; then
  KIND="kubectl ${BASH_REMATCH[2]}"
elif [[ "$SCAN" =~ $aws_re ]]; then
  KIND="aws ${BASH_REMATCH[2]}"
fi
[[ -z "$KIND" ]] && exit 0

# 環境は -prd/-stg/-dev（_ 区切りも可）で終わる名前から判定する。/dev/null など区切りの無い dev は拾わない。
detect_env() {
  local s="$1"
  if   [[ "$s" =~ [-_]prd([^[:alnum:]]|$) ]]; then echo prd
  elif [[ "$s" =~ [-_]stg([^[:alnum:]]|$) ]]; then echo stg
  elif [[ "$s" =~ [-_]dev([^[:alnum:]]|$) ]]; then echo dev
  elif [[ "$s" =~ minikube ]]; then echo local
  else echo unknown
  fi
}

ENV_NAME="unknown"
if [[ "$KIND" == kubectl* ]]; then
  ENV_NAME=$(detect_env "$SCAN")
  if [[ "$ENV_NAME" == unknown && ! "$SCAN" =~ --context([=[:space:]]) ]]; then
    ENV_NAME=$(detect_env "$(kubectl config current-context 2>/dev/null)")
  fi
else
  # 環境を区別できないため、-dev で終わる profile 以外（未指定を含む）は prd 扱いに倒す
  if [[ "$SCAN" =~ (--profile[=[:space:]]+|AWS_PROFILE=)[^[:space:]]*[-_]dev([^[:alnum:]]|$) ]]; then
    ENV_NAME=dev
  else
    ENV_NAME=prd
  fi
fi

[[ "$ENV_NAME" == local ]] && exit 0

SHOWN="${COMMAND:0:300}"
case "$ENV_NAME" in
  prd)     REASON="[prd] ${KIND}: 対話実行は実行前にユーザーの確認が必須。参照系コマンド (kubectl get/logs 等) で足りないか先に検討する。 実行内容: ${SHOWN}" ;;
  stg|dev) REASON="[${ENV_NAME}] ${KIND}: 対話実行はユーザーの確認のうえ実行する。 実行内容: ${SHOWN}" ;;
  *)       REASON="[環境不明] ${KIND}: 実行先の環境を特定できない（--context が変数、または current-context が未設定）。prd として扱いユーザーの確認が必須。 実行内容: ${SHOWN}" ;;
esac

jq -n --arg r "$REASON" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
exit 0
