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
function fzf-select-history() {
  BUFFER=$(history -n 1 | tac | fzf --query="$LBUFFER")
  CURSOR=$#BUFFER
  zle redisplay
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history

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
# relase 切って master PR 作る
#=============================
git-release-cut-pr() {
  local base="${1:-origin/develop}"
  local target_base="${2:-master}"
  local label="${3:-リリース報告なし}"   # 存在時のみ付与

  # 本文テンプレ（展開を防ぐためクォート付き heredoc）
  local body
  body=$(cat <<'EOF'
以下をリリースします
- aaa
- bbb
- [ ] label の付与について見直し
EOF
)

  # 1) 基準更新
  git fetch origin || return 1

  # 2) SHA 決定（12桁）
  local sha
  sha="$(git rev-parse --short=12 "$base")" || return 1

  # 3) "release" ブランチ衝突チェック（あると release/<sha> が作れない）
  if git show-ref --quiet --verify refs/heads/release || git ls-remote --exit-code --heads origin release >/dev/null 2>&1; then
    echo "❌ 'release' ブランチが存在するので 'release/$sha' は作れないよ。削除するか命名を変えてね（例: release-$sha）"
    return 1
  fi

  local branch="release/$sha"

  # 4) 既存なら checkout、無ければ作成して push
  if git rev-parse --verify "$branch" >/dev/null 2>&1; then
    git switch "$branch" || return 1
  else
    git switch -c "$branch" "$base" || return 1
    git push -u origin "$branch" || return 1
  fi

  # 5) ラベル存在チェック → あれば付与
  local label_opts=()
  if gh label list --limit 1000 | grep -Fq "$label"; then
    label_opts+=(--label "$label")
  fi

  # 6) Draft で作成（本文テンプレを渡す）→ 直後にブラウザで編集
  gh pr create \
    --base "$target_base" \
    --head "$branch" \
    --title "release: $sha" \
    --assignee @me \
    "${label_opts[@]}" \
    --body "$body" \
    --draft || return 1

  gh pr edit --web --head "$branch" || return 1

  echo "✅ Draft PR created & opened: $branch -> $target_base （assignee: @me, label: ${label_opts[*]:-(none)}）"
}

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
function k-desc-pod() {
  local pod=$(kubectl get pod --no-headers -o custom-columns=":metadata.name" | fzf)
  if [[ -n "$pod" ]]; then
    kubectl describe pod "$pod"
  fi
}

#=============================
# k8s で pod 選んで log
#=============================
function k-log-pod() {
  local pod=$(kubectl get pod --no-headers -o custom-columns=":metadata.name" | fzf)
  if [[ -n "$pod" ]]; then
    kubectl logs "$pod"
  fi
}

## マルチコンテナ対応バージョン
function k-log-multic() {
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
function k-exec() {
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
