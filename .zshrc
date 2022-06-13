export LC_ALL=en_US.UTF-8
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
#
#=============================
# include common settings
#=============================
source ~/.shellrc

#=============================
# exec fish`
#=============================
# case $- in
#     *i*) exec fish;;
#       *) return;;
# esac

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
# for hub
#=============================
function git(){hub "$@"}

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
function peco-select-history() {
    local tac
    if which tac > /dev/null; then
        tac="tac"
    else
        tac="tail -r"
    fi
    BUFFER=$(history -n 1 | \
        eval $tac | \
        peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

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
# Appearance & prompt
#=============================
# font は https://gist.github.com/qrush/1595572#file-menlo-powerline-otf を利用
# 一度 ↑ を入れてから ricty に変えたら記号が見えたっぽい. 謎
# DEFAULT=$'\U1F411 ' # ひつじ
# DEFAULT=$'\U1F30E ' # 地球
DEFAULT='$' # シンプルに
# # ERROR=$'\U1F363'   # スシ
# ERROR=$'\U1F47A'   # 天狗
BRANCH=$'\U2B60'   # ブランチ

autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*:-all-' command /usr/bin/git
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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/shimizu/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/shimizu/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/shimizu/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/shimizu/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

