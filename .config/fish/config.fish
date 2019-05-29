# eval(cat ~/.shellrc | grep alias | grep -v '#')
# bass source ~/.shellrc.local

alias rm='rmtrash'
alias sn='cat ~/.snippets ~/.snippets.local | peco --query "$LBUFFER" | sed -e "s/ *##.*//" | tr -d '\r\n' | pbcopy'
alias each='string match -q -e "{}" -- $argv || set -a argv {}; xargs -L1 -I{} $argv;:'
alias g='git'

## git commnad to hub
eval (hub alias -s)

## comnmands
function puts
    for s in $argv
        echo $s
    end
end

function snippets
    cat ~/.snippets ~/.snippets.local | peco --query "$LBUFFER" | sed -e "s/ *##.*//" | tr -d '\r\n' | pbcopy
end

## keybinds
function fish_user_key_bindings
  bind \cr 'peco_select_history (commandline -b)'
  bind \cg peco_select_ghq_repository
  bind \cx snippets
#   bind \cx\cr peco_recentd
#   bind \cx\ck peco_kill
end
