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
source ./.shellrc
