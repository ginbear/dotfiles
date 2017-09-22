#=============================
# include common settings
#=============================
source ~/.shellrc
source ~/.zsh/*.zsh

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
# http://qiita.com/harapeko_wktk/items/47aee77e6e7f7800fa03
#=============================
fpath=(/usr/local/share/zsh-completions $fpath)
autoload -Uz compinit
compinit -u

#=============================
# for hub
#=============================
function git(){hub "$@"}

#=============================
# for git worktree
#=============================
function gwt() {
    GIT_CDUP_DIR=`git rev-parse --show-cdup`
    git worktree add ${GIT_CDUP_DIR}tmp/$1 -b $1
}

#=============================
# peco + ssh
#=============================
function peco-ssh () {
  local selected_host=$(awk '
  tolower($1)=="host" {
    for (i=2; i<=NF; i++) {
      if ($i !~ "[*?]") {
        print $i
      }
    }
  }
  ' <(cat ~/.ssh/config ~/.ssh/config.*) | sort | peco --query "$LBUFFER")
  if [ -n "$selected_host" ]; then
    BUFFER="ssh ${selected_host}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-ssh
bindkey '^t' peco-ssh

#=============================
# peco の結果に $1 する. p cd とか
# http://r7kamura.github.io/2014/06/21/ghq.html
#=============================
p() { peco | while read LINE; do $@ $LINE; done }

#=============================
# snippets
# http://blog.glidenote.com/blog/2014/06/26/snippets-peco-percol/
#=============================
function peco-snippets() {
    local SNIPPETS=$(cat ~/.snippets ~/.snippets.local | peco --query "$LBUFFER" | sed -e "s/ *##.*//" | tr -d '\r\n' | pbcopy)
#     zle clear-screen
}
zle -N peco-snippets
bindkey '^x' peco-snippets

#=============================
# ghq look
#=============================
function ghq-look() {
    local GHQLOOK=$(ghq list -p | peco)
    cd $GHQLOOK
}
zle -N ghq-look
bindkey '^G' ghq-look

#=============================
# history を peco で選択
# http://blog.kenjiskywalker.org/blog/2014/06/12/peco/
#=============================
# function peco-select-history() {
#     local tac
#     if which tac > /dev/null; then
#         tac="tac"
#     else
#         tac="tail -r"
#     fi
#     BUFFER=$(history -n 1 | \
#         eval $tac | \
#         peco --query "$LBUFFER")
#     CURSOR=$#BUFFER
#     zle clear-screen
# }
# zle -N peco-select-history
# bindkey '^r' peco-select-history

#=============================
# history
# http://www.tellme.tokyo/entry/2017/06/13/233305
#=============================
# 
# GITHUB_TOKEN=""
# ZSH_HISTORY_AUTO_SYNC="true"
# ZSH_HISTORY_KEYBIND_GET="^r"
# ZSH_HISTORY_FILTER_OPTIONS="--filter-branch --filter-dir"
# ZSH_HISTORY_KEYBIND_ARROW_UP="^p"
# ZSH_HISTORY_KEYBIND_ARROW_DOWN="^n"
#
#=============================
# history
# http://qiita.com/syui/items/c1a1567b2b76051f50c4
#=============================
# 履歴ファイルの保存先
export HISTFILE=${HOME}/.zsh_history

# メモリに保存される履歴の件数
export HISTSIZE=1000

# 履歴ファイルに保存される履歴の件数
export SAVEHIST=100000

# 重複を記録しない
setopt hist_ignore_dups

# 開始と終了を記録
setopt EXTENDED_HISTORY

# ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_all_dups

# スペースで始まるコマンド行はヒストリリストから削除
setopt hist_ignore_space

# ヒストリを呼び出してから実行する間に一旦編集可能
setopt hist_verify

# 余分な空白は詰めて記録
setopt hist_reduce_blanks  

# 古いコマンドと同じものは無視 
setopt hist_save_no_dups

# historyコマンドは履歴に登録しない
setopt hist_no_store

# 補完時にヒストリを自動的に展開
setopt hist_expand

# 履歴をインクリメンタルに追加
setopt inc_append_history

#=============================
# auto-fu.zsh
#=============================
if [ -f ~/.zsh/auto-fu.zsh ]; then
    source ~/.zsh/auto-fu.zsh
    function zle-line-init () {
        auto-fu-init
    }
    zle -N zle-line-init
    zstyle ':completion:*' completer _oldlist _complete
fi

#=============================
# Appearance & prompt
#=============================
# DEFAULT=$'\U1F411 ' # ひつじ
# DEFAULT=$'\U1F30E ' # 地球
DEFAULT='$' # シンプルに
# ERROR=$'\U1F363'   # スシ
ERROR=$'\U1F47A'   # 天狗
BRANCH=$'\U2B60'   # ブランチ

autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u%r ${BRANCH}%b$ %f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }
# PROMPT='${vcs_info_msg_0_}%% '

autoload -Uz colors
colors

PROMPT='%(?.${DEFAULT}.%{${fg[red]}%}${DEFAULT}%{${reset_color}%}) ${vcs_info_msg_0_}'
