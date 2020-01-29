# ~/.bashrc: executed by bash for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return ;;
esac

# Source global definitions
# include /etc/bashrc if it exists
if [[ -f /etc/bashrc ]]; then
	. /etc/bashrc
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# some more ls aliases
alias lsa='ls -AF'
alias l='ls -alhF'
alias ll='ls -lhF'
alias la='ls -AlhF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
if [ -f "$HOME/.bash_aliases" ]; then
	. "$HOME/.bash_aliases"
fi

# enable programmable completion features
if ! shopt -oq posix; then
	if [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]]; then
		. "/usr/local/etc/profile.d/bash_completion.sh"
	elif [[ -f "/usr/share/bash-completion/bash_completion" ]]; then
		. "/usr/share/bash-completion/bash_completion"
	elif [[ -f "/etc/bash_completion" ]]; then
		. "/etc/bash_completion"
	fi
fi

# always source ~/.bash_profile
if ! shopt -q login_shell; then
	# include ~/.bash_profile if it exists
	if [[ -f "$HOME/.bash_profile" ]]; then
		. "$HOME/.bash_profile"
	elif [[ -f "$HOME/.profile" ]]; then
		. "$HOME/.profile"
	fi
fi
