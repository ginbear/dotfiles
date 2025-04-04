# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH

# export PS1="$ "
export HISTIGNORE=ls:history

# include common settings
source ~/.shellrc

# for hub 
eval "$(hub alias -s)"

complete -C /usr/local/bin/vault vault

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/shimizu/opt/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
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


### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/shimizu/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
