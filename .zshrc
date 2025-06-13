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
  export AWS_PROFILE=$(rg -oP '^\[\K[^\]]+' ~/.aws/config | cut -f 2 -d " " | sort | uniq | fzf)
  echo "Switched to profile: $AWS_PROFILE"
}

#=============================
# AWS SSO LOGIN を 1 日一回やる
#=============================
AWS_SSO_LOGIN_STAMP_FILE="$HOME/.aws_sso_login_last"

if [ ! -f "$AWS_SSO_LOGIN_STAMP_FILE" ] || [ "$(date +%Y-%m-%d)" != "$(cat $AWS_SSO_LOGIN_STAMP_FILE)" ]; then
  for AWS_SSO_PROFILE in $(grep -oP '^\[\K[^\]]+' ~/.aws/config | cut -f 2 -d " " | sort | uniq ) 
  do
    echo "Running aws sso login for profile $AWS_SSO_PROFILE..."
    aws sso login --profile "$AWS_SSO_PROFILE"
  done
  date +%Y-%m-%d > "$AWS_SSO_LOGIN_STAMP_FILE"
fi

#=============================
# for hub
#=============================
function git(){hub "$@"}

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
