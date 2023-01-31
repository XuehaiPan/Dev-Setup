# ~/.bashrc: executed by bash for non-login shells.

# If not running interactively, don't do anything
case $- in
	*i*) ;;
	*) return ;;
esac

# Source global definitions
# Include /etc/bashrc if it exists
if [[ -f /etc/bashrc ]]; then
	source /etc/bashrc
fi

# Don't put duplicate lines or lines starting with space in the history.
# See bash for more options
HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it
shopt -s histappend

# For setting history length see HISTSIZE and HISTFILESIZE in bash
HISTSIZE=1000
HISTFILESIZE=2000

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# Some more ls aliases
alias lsa='ls -AF'
alias l='ls -alhF'
alias ll='ls -lhF'
alias la='ls -AlhF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
if [[ -f "${HOME}/.bash_aliases" ]]; then
	source "${HOME}/.bash_aliases"
fi

# Enable programmable completion features
if ! shopt -oq posix; then
	if [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]]; then
		source "/usr/local/etc/profile.d/bash_completion.sh"
	elif [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]]; then
		source "/opt/homebrew/etc/profile.d/bash_completion.sh"
	elif [[ -f "/usr/share/bash-completion/bash_completion" ]]; then
		source "/usr/share/bash-completion/bash_completion"
	elif [[ -f "/etc/bash_completion" ]]; then
		source "/etc/bash_completion"
	fi
fi

# Always source ~/.bash_profile
if ! shopt -q login_shell; then
	# Include ~/.bash_profile if it exists
	if [[ -f "${HOME}/.bash_profile" ]]; then
		source "${HOME}/.bash_profile"
	elif [[ -f "${HOME}/.profile" ]]; then
		source "${HOME}/.profile"
	fi
fi
