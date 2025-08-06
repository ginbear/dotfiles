eval "$(/opt/homebrew/bin/brew shellenv)"
export LC_ALL=en_US.UTF-8
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export FZF_DEFAULT_OPTS='--height 40% --reverse --border --no-sort'

#=============================
# include common settings
#=============================
source ~/.shellrc

#=============================
# zsh settings
#=============================
# Ctrl-A, E とか効かせる
bindkey -e

## 単語の定義を bash と同じにする
autoload -U select-word-style
select-word-style bash

#=============================
# zsh-completions
#=============================
fpath=(/usr/local/share/zsh-completions $fpath)
autoload -Uz compinit
compinit -u

#=============================
# for aws
#=============================
function aws-profile() {
  local AWS_PROFILE_SELECTED
  local AWS_SSO_LOGIN_STAMP_DIR="$HOME/.aws/sso_login_timestamps"
#  local CURRENT_TIME=$(date +%s) # 現在時刻をUnixエポック秒で取得

  # プロファイルを選択
  AWS_PROFILE_SELECTED=$(rg -oP '^\[\K[^\]]+' ~/.aws/config | cut -f 2 -d " " | sort | uniq | fzf)

  if [ -z "$AWS_PROFILE_SELECTED" ]; then
    echo "プロファイルが選択されませんでした。"
    return 1
  fi

  export AWS_PROFILE="$AWS_PROFILE_SELECTED"
  echo "Switched to profile: $AWS_PROFILE"
  echo "exec: aws sso login --profile $AWS_PROFILE_SELECTED"
  aws sso login --profile "$AWS_PROFILE_SELECTED"

#   # ログインタイムスタンプディレクトリが存在しない場合は作成
#   mkdir -p "$AWS_SSO_LOGIN_STAMP_DIR"
# 
#   local STAMP_FILE="$AWS_SSO_LOGIN_STAMP_DIR/${AWS_PROFILE_SELECTED}.timestamp"
#   local LAST_LOGIN_TIME=0
# 
#   # 過去のログイン時刻を読み込む
#   if [ -f "$STAMP_FILE" ]; then
#     LAST_LOGIN_TIME=$(cat "$STAMP_FILE")
#   fi
# 
#   local SEVENTY_TWO_HOURS_IN_SECONDS=$((24 * 60 * 60))
# 
#   # 前回のログインから72時間以上経過しているかチェック
#   if [ $((CURRENT_TIME - LAST_LOGIN_TIME)) -ge "$SEVENTY_TWO_HOURS_IN_SECONDS" ]; then
#     echo "前回のログインから72時間以上経過しました。aws sso login を実行します..."
#     if aws sso login --profile "$AWS_PROFILE_SELECTED"; then
#       echo "$CURRENT_TIME" > "$STAMP_FILE" # ログイン成功時にタイムスタンプを更新
#       echo "aws sso login が正常に完了しました。"
#     else
#       echo "aws sso login に失敗しました。"
#     fi
#   else
#     echo "前回のログインから72時間以内です。aws sso login はスキップします。"
#   fi
}

#=============================
# for hub
#=============================
# function git(){hub "$@"}

#=============================
# git 補完
#=============================
fpath=(~/.zsh/completion $fpath)

# 補完機能を有効化
autoload -Uz compinit
compinit

function gsw() {
  local branch=$(git branch | sed 's/^[* ] //' | fzf)
  [[ -n "$branch" ]] && git switch "$branch"
}

#=============================
# peco の結果に $1 する. p cd とか
# http://r7kamura.github.io/2014/06/21/ghq.html
#=============================
p() { peco | while read LINE; do $@ $LINE; done }

#=============================
# snippets with fzf
#=============================
function fzf-snippets() {
  local SNIPPETS=$(cat ~/.snippets | fzf --query="$LBUFFER" | sed -e "s/ *##.*//" | tr -d '\r\n' | pbcopy)
}
zle -N fzf-snippets
bindkey '^x' fzf-snippets

#=============================
# ghq look with fzf
#=============================
function fzf-ghq-look() {
  local dir=$(ghq list -p | fzf)
  if [[ -n "$dir" ]]; then
    cd "$dir"
  fi
}
zle -N fzf-ghq-look
bindkey '^G' fzf-ghq-look

#=============================
# history with fzf
#=============================
function fzf-select-history() {
  BUFFER=$(history -n 1 | tac | fzf --query="$LBUFFER")
  CURSOR=$#BUFFER
  zle redisplay
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history

#=============================
# history
# http://qiita.com/syui/items/c1a1567b2b76051f50c4
#=============================
export HISTFILE=${HOME}/.zsh_history        # 履歴ファイルの保存先
export HISTSIZE=1000                        # メモリに保存される履歴の件数
export SAVEHIST=100000                      # 履歴ファイルに保存される履歴の件数
setopt hist_ignore_dups                     # 直前と重複するコマンドは記録しない
setopt EXTENDED_HISTORY                     # 開始と終了のタイムスタンプも記録
setopt hist_ignore_all_dups                 # 古い重複コマンドを削除して新しいのだけ残す
setopt hist_ignore_space                    # スペースで始まるコマンドは記録しない
setopt hist_verify                          # 履歴からの実行前に編集可能
setopt hist_reduce_blanks                   # 余分な空白を詰めて記録
setopt hist_save_no_dups                    # 同一コマンドを履歴に保存しない
setopt hist_no_store                        # `history` コマンド自体を履歴に残さない
setopt hist_expand                          # 補完時にヒストリ展開を有効にする
setopt inc_append_history                   # コマンド実行ごとに履歴を即座に保存

#=============================
# k8s で context をいい感じに選ぶ
#=============================
function kctx() {
  local ctx=$(kubectl config get-contexts -o name | fzf)
  if [[ -n "$ctx" ]]; then
    kubectl config use-context "$ctx"
  fi
}

#=============================
# k8s で namespace をいい感じに選ぶ
#=============================
function kns() {
  local ns=$(kubectl get ns --no-headers | awk '{print $1}' | fzf)
  if [[ -n "$ns" ]]; then
    kubectl config set-context --current --namespace="$ns"
    echo "Switched to namespace: $ns"
  fi
}

#=============================
# k8s で pod 選んで describe
#=============================
function kpod() {
  local pod=$(kubectl get pod --no-headers -o custom-columns=":metadata.name" | fzf)
  if [[ -n "$pod" ]]; then
    kubectl describe pod "$pod"
  fi
}

#=============================
# k8s で pod 選んで log
#=============================
function klog() {
  local pod=$(kubectl get pod --no-headers -o custom-columns=":metadata.name" | fzf)
  if [[ -n "$pod" ]]; then
    kubectl logs "$pod"
  fi
}

## マルチコンテナ対応バージョン
function klogc() {
  local pod=$(kubectl get pod --no-headers -o custom-columns=":metadata.name" | fzf)
  if [[ -z "$pod" ]]; then return; fi

  local containers=$(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].name}')
  local container=$(echo "$containers" | tr ' ' '\n' | fzf)
  if [[ -n "$container" ]]; then
    kubectl logs "$pod" -c "$container"
  fi
}

#=============================
# k8s で pod 選んで exec -it
#=============================
function kexec() {
  local pod=$(kubectl get pod --no-headers -o custom-columns=":metadata.name" | fzf)
  if [[ -n "$pod" ]]; then
    local bash_path
    bash_path=$(kubectl exec "$pod" -- which bash 2>/dev/null)
    if [[ -n "$bash_path" ]]; then
      kubectl exec -it "$pod" -- "$bash_path"
    else
      kubectl exec -it "$pod" -- /bin/sh
    fi
  fi
}

#=============================
# k8s/kustomization する対象を選んで実行
#=============================
function ksbf() {
  local dir=$(find . -name kustomization.yaml | sed 's|/kustomization.yaml||' | fzf)
  if [[ -n "$dir" ]]; then
    kustomize build "$dir"
  fi
}

#=============================
# Powerlevel10k
#=============================
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

## https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#installation
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#=============================
# for production settings
#=============================

if [[ "$ENV_TYPE" == "production" ]]; then

#   export LOGFILE=~/.logs/zsh-session-$(date +%F-%H%M%S)-$$.log
#   mkdir -p ~/.logs
#   echo "[LOG START $(date)]" >> "$LOGFILE"
# 
#   # stdout, stderr を tee に流す
#   exec >> "$LOGFILE" 2>&1
# 
#   # preexec フック：コマンド直前のログ
#   function log_command_with_timestamp() {
#     echo "" >&2
#     echo "## [$(date '+%F %T')] Running: $1" >&2
#   }
#   autoload -Uz add-zsh-hook
#   add-zsh-hook preexec log_command_with_timestamp

  # Powerlevel10k のプロンプト制御
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir
    vcs
    time
  )

fi

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
