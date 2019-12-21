# .bashrc

# Source global definitions

# include /etc/bashrc if it exists
if [[ -f /etc/bashrc ]]; then
	. /etc/bashrc
fi

# User specific aliases and functions

alias la="ls -A"
alias ll="ls -AlFh"

# User specific environment and startup programs

export TERM="xterm-256color"
export GREP_OPTIONS='--color=auto' GREP_COLOR='1;32'
export CLICOLOR=1
export LSCOLORS="GxFxCxDxBxegedabagaced"
export PS1='[\[\e[1;33m\]\u\[\e[0m\]@\[\e[1;32m\]\h\[\e[0m\]:\[\e[1;35m\]\W\[\e[0m\]]\$ '
