eval "$(/opt/homebrew/bin/brew shellenv)"
export LC_ALL=en_US.UTF-8
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export FZF_DEFAULT_OPTS='--height 70% --reverse --border --tiebreak=length,index'

#=============================
# include common settings
#=============================
source ~/.shellrc

#=============================
# zsh settings
#=============================
# Ctrl-A, E とか効かせる
bindkey -e

#=============================
# Ctrl w で空白まで削除、Esc delete で記号まで削除
#=============================
# 1) 共有の -match 関数を読み込む（済ならOK）
autoload -U backward-kill-word-match

# 2) 2つのウィジェットを作る
zle -N backward-kill-space  backward-kill-word-match   # 空白区切り
zle -N backward-kill-punct  backward-kill-word-match   # 記号区切り

# 3) 各ウィジェットごとに word-style を変える
zstyle ':zle:backward-kill-space' word-style whitespace
zstyle ':zle:backward-kill-punct' word-style normal     # ← $WORDCHARS に従う

# 4) . と - を「語に含めない」＝そこで止めたいなら WORDCHARS を調整
# typeset -g WORDCHARS='*?_[]~=/&;!#$%^(){}<>'  # （. と - を入れない）

# 5) キー割り当て
bindkey '^W'      backward-kill-space        # Ctrl-W = 空白まで削除
bindkey '^[^?'    backward-kill-punct        # Esc+Backspace = .や-で区切って削除
#   ↑ Esc+Delete の送出シーケンス（環境で違う場合は後述の zkbd を使って検出）


## 単語の定義を bash と同じにする
autoload -U select-word-style
select-word-style bash

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
# zsh-completions
#=============================
fpath=(/usr/local/share/zsh-completions $fpath)
autoload -Uz compinit
compinit -u

#=============================
# peco の結果に $1 する. p cd とか
# http://r7kamura.github.io/2014/06/21/ghq.html
#=============================
p() { peco | while read LINE; do $@ $LINE; done }

#=============================
# 関数を呼び出す関数
#=============================
fn-fzf() {
  local sel
  sel=$(
    print -l ${(k)functions} | while read -r fn; do
      [[ ${functions_source[$fn]} == "$HOME/.zshrc" ]] && echo "$fn"
    done |
    sort |
    fzf --prompt="Zshrc Function> " \
        --preview='functions {} | sed -n "1,200p"' \
        --preview-window=down,60%
  ) || return
  print -z "$sel "
}

#=============================
# for aws
#=============================
function aws-profile() {
  local AWS_PROFILE_SELECTED
  local AWS_SSO_LOGIN_STAMP_DIR="$HOME/.aws/sso_login_timestamps"

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
}

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
# function fzf-select-history() {
#   BUFFER=$(history -n -r 1 | awk '!seen[$0]++' | \
#     fzf --no-sort \
#         --query="$LBUFFER" \
#         --height 50% \
#         --border \
#         --prompt="History> " \
#         --bind 'ctrl-/:toggle-preview' \
#         --preview 'echo {}' \
#         --preview-window=down:3:wrap)
#   CURSOR=$#BUFFER
#   zle redisplay
# }
# zle -N fzf-select-history
# bindkey '^r' fzf-select-history
export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"

bindkey '^r' atuin-search

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
# pr list for me
#=============================
git-pr() {
  local state="${1:-open}"  # open / closed / merged / all
  local q="is:pr author:@me sort:updated-desc"
  [ "$state" != "all" ] && q="$q state:$state"

  gh api graphql -F q="$q" -f query='
    query($q: String!) {
      search(query: $q, type: ISSUE, first: 100) {
        nodes {
          ... on PullRequest {
            url
            title
            number
            updatedAt
            repository { nameWithOwner }
          }
        }
      }
    }' \
  | jq -r '.data.search.nodes[] | "\(.url)\t[\(.repository.nameWithOwner)] #\(.number)  \(.title)  (updated: \(.updatedAt))"' \
  | fzf --with-nth=2.. --prompt="my PRs ($state)> " \
  | cut -f1 \
  | xargs -r -n1 gh pr view --web
}

#=============================
# release 切って master PR 作る（private: .local.sh に分離）
#=============================
[[ -f ~/.config/zsh-profiles/git-release-cut-pr.local.sh ]] && source ~/.config/zsh-profiles/git-release-cut-pr.local.sh

#=============================
# difffff
#=============================
git-pr-diff () {
  local pr="${1:?usage: prdiff-bases <PR#> [pattern]}"
  local pat="${2:-/bases/}"
  gh pr diff "$pr" \
  | awk -v p="$pat" '/^diff --git/ {show = ($0 ~ p)} {if (show) print}' \
  | grep -v 'last-update-date' \
  | grep -E '^(diff --git|index |--- |\+\+\+ |@@ |\+|-) ' \
  | delta --keep-plus-minus-markers
}

#=============================
# k8s で context をいい感じに選ぶ
#=============================
kctx() {
  local current choice ctx
  current="$(kubectl config current-context 2>/dev/null)"

  choice="$(
    kubectl config get-contexts -o name | while read -r real; do
      display="$(sed -E 's#^arn:aws:eks:[^:]+:[0-9]+:cluster/##' <<<"$real")"
      display="${display##*/}"
      mark=" "
      [[ "$real" == "$current" ]] && mark="*"
      printf "%s\t%s\t%s\n" "$mark" "$display" "$real"
    done | fzf \
      --prompt='select context > ' \
      --header=$'CURRENT\tNAME' \
      --delimiter='\t' \
      --with-nth=1,2 \
      --nth=2 \
      --select-1 --exit-0
  )" || return

  ctx="$(awk -F'\t' '{print $3}' <<<"$choice")"
  [[ -n "$ctx" ]] || return
  kubectl config use-context "$ctx"
}

#=============================
# k8s で namespace をいい感じに選ぶ
#=============================
kns() {
  local current choice ns
  current="$(kubectl config view --minify -o 'jsonpath={..namespace}' 2>/dev/null)"
  [[ -z "$current" ]] && current="default"

  choice="$(
    kubectl get ns --no-headers \
      | awk -v cur="$current" '{
          # $1=NAME, $2=STATUS, $3=AGE
          mark = ($1==cur) ? "*" : "-";   # ← 空白ではなく "-" を使う
          printf "%s\t%s\t%s\t%s\n", mark, $1, $2, $3
        }' \
      | column -t -s $'\t' \
      | fzf \
          --prompt='select namespace > ' \
          --with-nth=1,2,3,4 \
          --nth=2 \
          --delimiter='[[:space:]]+' \
          --select-1 --exit-0
  )" || return

  # 整形後も 2 列目が NAME
  ns="$(awk '{print $2}' <<<"$choice")"
  [[ -n "$ns" ]] || return

  kubectl config set-context --current --namespace="$ns"
  echo "Switched to namespace: $ns"
}

#=============================
# k8s で pod 選んで describe
#=============================
k-desc-pod() {
  local line
  line="$(
    kubectl get pods -A \
    | fzf \
        --header='↑↓で選択 / NAME列だけで検索 / Enterで describe（右でプレビュー）' \
        --header-lines=1 \
        --delimiter='\s+' \
        --nth=2 \
        --preview '
          ns=$(awk "{print \$1}" <<< {}); \
          name=$(awk "{print \$2}" <<< {}); \
          [[ "$ns" == "NAMESPACE" ]] && echo "header" && exit 0; \
          # 重くなりすぎないように describe を120行だけ
          kubectl describe pod -n "$ns" "$name" 2>/dev/null | sed -n "1,120p"
        ' \
        --preview-window=right:40%:wrap
  )" || return

  local ns name
  ns="$(awk '{print $1}' <<<"$line")"
  name="$(awk '{print $2}' <<<"$line")"

  [[ -n "$ns" && -n "$name" ]] || return
  kubectl describe pod -n "$ns" "$name"
}

#=============================
# k8s で pod 選んで log
#=============================
function k-log-pod() {
  local pod=$(kubectl get pod --no-headers -o custom-columns=":metadata.name" | fzf  --prompt="選んだpodのlogを取得するよ: ")
  if [[ -n "$pod" ]]; then
    kubectl logs "$pod"
  fi
}

## マルチコンテナ対応バージョン
function k-log-multic() {
  local pod=$(kubectl get pod --no-headers -o custom-columns=":metadata.name" | fzf --prompt="選んだpodのlogを取得するよ（マルチコンテナ対応）: ")
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
function k-exec() {
  local pod=$(kubectl get pod --no-headers -o custom-columns=":metadata.name" | fzf --prompt="選んだpodにshell loginするよ: ")
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
# k8s/サービスアカウント選んで rolesum を実行する
#=============================
function k-role() {
  local serviceaccount namespace name

  serviceaccount=$(
    kubectl get serviceaccount \
      --all-namespaces \
      -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name \
    | fzf --prompt="Select a Role: " --header-lines=1
  )

  [[ -z "$serviceaccount" ]] && return 1

  namespace=$(echo "$serviceaccount" | awk '{print $1}')
  name=$(echo "$serviceaccount" | awk '{print $2}')

  kubectl rolesum "$name" -n "$namespace"
}

#=============================
# k8s/kustomization する対象を選んで実行
#=============================
function ks-build() {
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

  # Powerlevel10k のプロンプト制御
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir
    vcs
    time
  )

fi

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
eval "$(mise activate zsh)"
