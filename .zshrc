# include common settings
source ./.shellrc

# zsh-completions
# http://qiita.com/harapeko_wktk/items/47aee77e6e7f7800fa03
fpath=(/usr/local/share/zsh-completions $fpath)
autoload -Uz compinit
compinit -u

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git 

# 下のformatsの値をそれぞれの変数に入れてくれる機能の、変数の数の最大。
# デフォルトだと2くらいなので、指定しておかないと、下のformatsがほぼ動かない。
zstyle ':vcs_info:*' max-exports 7

# 左から順番に、vcs_info_msg_{n}_ という名前の変数に格納されるので、下で利用する
zstyle ':vcs_info:*' formats '%R' '%S' '%b' '%s'
# 状態が特殊な場合のformats
zstyle ':vcs_info:*' actionformats '%R' '%S' '%b|%a' '%s'

# 4.3.10以上の場合は、check-for-changesという機能を使う。
autoload -Uz is-at-least
if is-at-least 4.3.10; then
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' formats '%R' '%S' '%b' '%s' '%c' '%u'
    zstyle ':vcs_info:*' actionformats '%R' '%S' '%b|%a' '%s' '%c' '%u'
fi

# cdr
autoload -Uz is-at-least
if is-at-least 4.3.11
then
  autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
  add-zsh-hook chpwd chpwd_recent_dirs
  zstyle ':chpwd:*' recent-dirs-max 5000
  zstyle ':chpwd:*' recent-dirs-default yes
  zstyle ':completion:*' recent-dirs-insert both
fi

# http://r7kamura.github.io/2014/06/21/ghq.html
# peco の結果に $1 する. p cd とか
p() { peco | while read LINE; do $@ $LINE; done }

# zshのPTOMPTに渡す文字列は、可読性がそんなに良くなくて、読み書きしたり、つまりデバッグが
# 大変なため、文字列を組み立てるのは関数でやることにする。
# そのほうが分岐などを追加するのが楽。
# この先、追加で表示させたい情報はいろいろでてくるとおもうし。
function echo_rprompt () {
    local repos branch st color

    STY= LANG=en_US.UTF-8 vcs_info
    if [[ -n "$vcs_info_msg_1_" ]]; then
        # -Dつけて、~とかに変換
        repos=`print -nD "$vcs_info_msg_0_"`

        # if [[ -n "$vcs_info_msg_2_" ]]; then
            branch="$vcs_info_msg_2_"
        # else
        #     branch=$(basename "`git symbolic-ref HEAD 2> /dev/null`")
        # fi

        if [[ -n "$vcs_info_msg_4_" ]]; then # staged
            branch="%F{green}$branch%f"
        elif [[ -n "$vcs_info_msg_5_" ]]; then # unstaged
            branch="%F{red}$branch%f"
        else
            branch="%F{blue}$branch%f"
        fi

        print -n "[%25<..<"
        print -n "%F{yellow}$vcs_info_msg_1_%F"
        print -n "%<<]"

        print -n "[%15<..<"
        print -nD "%F{yellow}$repos%f"
        print -n "@$branch"
        print -n "%<<]"

    else
        print -nD "[%F{yellow}%60<..<%~%<<%f]"
    fi
}

setopt prompt_subst
RPROMPT='`echo_rprompt`'

# snippets
# http://blog.glidenote.com/blog/2014/06/26/snippets-peco-percol/
function peco-snippets() {
    local SNIPPETS=$(cat ~/.snippets | peco --query "$LBUFFER" | sed -e "s/ *##.*//" | tr -d '\r\n' | pbcopy)
#     zle clear-screen
}
zle -N peco-snippets
bindkey '^x' peco-snippets

# history を peco で選択
# http://blog.kenjiskywalker.org/blog/2014/06/12/peco/
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

function peco-cdr () {
    local selected_dir=$(cdr -l | awk '{ print $2 }' | peco)
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-cdr
bindkey '^@' peco-cdr

## 単語の定義を bash と同じにする
autoload -U select-word-style
select-word-style bash

## http://shoma2da.hatenablog.com/entry/2014/03/26/222802
## hub config --global hub.host <ghe.address>
## https://github.com/github/hub/commit/7944d63edb1373fbbfa806bc108508b7906c8210
eval "$(hub alias -s)"

## Other
### tmux
#### http://blog.glidenote.com/blog/2014/02/22/remote-pbcopy/
# launchctl load ~/Library/LaunchAgents/pbcopy.plist




