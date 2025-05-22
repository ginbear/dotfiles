# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export LC_ALL=en_US.UTF-8
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

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
  export AWS_PROFILE=$(grep -oP '^\[\K[^\]]+' ~/.aws/config | cut -f 2 -d " " | sort | uniq | fzf)
  echo "Switched to profile: $AWS_PROFILE"
}

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

## https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#installation
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/shimizu/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
