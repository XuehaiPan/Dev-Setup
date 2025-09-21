# Source global definitions
# Include /etc/zprofile if it exists
if [[ -f /etc/zprofile ]]; then
	source /etc/zprofile
fi

# Include /etc/zshrc if it exists
if [[ -f /etc/zshrc ]]; then
	source /etc/zshrc
fi

# Set PATH so it includes user's private bin if it exists
if [[ -d "${HOME}/.local/bin" ]]; then
	export PATH="${HOME}/.local/bin${PATH:+:"${PATH}"}"
fi

# Set C_INCLUDE_PATH and CPLUS_INCLUDE_PATH so it includes user's private include if it exists
if [[ -d "${HOME}/.local/include" ]]; then
	export C_INCLUDE_PATH="${HOME}/.local/include${C_INCLUDE_PATH:+:"${C_INCLUDE_PATH}"}"
	export CPLUS_INCLUDE_PATH="${HOME}/.local/include${CPLUS_INCLUDE_PATH:+:"${CPLUS_INCLUDE_PATH}"}"
fi

# Set LIBRARY_PATH and DYLD_LIBRARY_PATH so it includes user's private lib if it exists
if [[ -d "${HOME}/.local/lib" ]]; then
	export LIBRARY_PATH="${HOME}/.local/lib${LIBRARY_PATH:+:"${LIBRARY_PATH}"}"
	export DYLD_LIBRARY_PATH="${HOME}/.local/lib${DYLD_LIBRARY_PATH:+:"${DYLD_LIBRARY_PATH}"}"
fi
if [[ -d "${HOME}/.local/lib64" ]]; then
	export LIBRARY_PATH="${HOME}/.local/lib64${LIBRARY_PATH:+:"${LIBRARY_PATH}"}"
	export DYLD_LIBRARY_PATH="${HOME}/.local/lib64${DYLD_LIBRARY_PATH:+:"${DYLD_LIBRARY_PATH}"}"
fi

# User specific environment
export TERM="xterm-256color"
export LESS="-R -M -i -j5"
export CLICOLOR=1
export LSCOLORS="${LSCOLORS:-"GxFxCxDxBxegedabagaced"}"

# Locale
export LANG="en_US.UTF-8"
export LANGUAGE="en:C"
if [[ -x "$(command -v locale)" ]]; then
	eval "$(printf "export %s\n" $(LC_ALL="" LC_TIME="C.UTF-8" locale))"
fi
export LC_ALL="${LANG}"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_BAT=true
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
export HOMEBREW_DOWNLOAD_CONCURRENCY="auto"
export HOMEBREW_EDITOR="vim"
export HOMEBREW_FORCE_VENDOR_RUBY=true
export HOMEBREW_NO_ANALYTICS=true
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
if [[ -d "$(brew --repository homebrew/core)/.git" ]]; then
	export HOMEBREW_NO_INSTALL_FROM_API=true
fi
__COMMAND_NOT_FOUND_HANDLER="${HOMEBREW_REPOSITORY}/Library/Homebrew/command-not-found/handler.sh"
if [[ -f "${__COMMAND_NOT_FOUND_HANDLER}" ]]; then
	source "${__COMMAND_NOT_FOUND_HANDLER}"
fi
unset __COMMAND_NOT_FOUND_HANDLER
function brew() { \command brew "$@"; \local rc="$?"; \builtin hash -r &>/dev/null; \return "${rc}"; }

# Anaconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$(CONDA_REPORT_ERRORS=false "${HOME}/Miniconda3/bin/conda" shell.zsh hook 2>/dev/null)"
if [[ $? -eq 0 ]]; then
	eval "${__conda_setup}"
else
	if [[ -f "${HOME}/Miniconda3/etc/profile.d/conda.sh" ]]; then
		source "${HOME}/Miniconda3/etc/profile.d/conda.sh"
	else
		export PATH="${HOME}/Miniconda3/bin${PATH:+:"${PATH}"}"
	fi
fi
unset __conda_setup

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_ROOT_PREFIX="${HOME}/Miniconda3/bin"
export MAMBA_EXE="${MAMBA_ROOT_PREFIX}/mamba"
__mamba_setup="$("${MAMBA_EXE}" shell hook --shell zsh --root-prefix "${MAMBA_ROOT_PREFIX}" 2>/dev/null)"
if [[ $? -eq 0 ]]; then
	eval "${__mamba_setup}"
else
	alias mamba="${MAMBA_EXE}"
fi
unset __mamba_setup
# <<< mamba initialize <<<

__CONDA_PREFIX="${CONDA_PREFIX}"
while [[ -n "${CONDA_PREFIX}" ]]; do
	conda deactivate
done
# <<< conda initialize <<<

# CXX Compilers
export CC="${CC:-"/usr/bin/gcc"}"
export CXX="${CXX:-"/usr/bin/g++"}"
export FC="${FC:-"${HOMEBREW_PREFIX}/bin/gfortran"}"
export OMPI_CC="${CC}" MPICH_CC="${CC}"
export OMPI_CXX="${CXX}" MPICH_CXX="${CXX}"
export OMPI_FC="${FC}" MPICH_FC="${FC}"

# Go
export GOPATH="${GOPATH:-"${HOME}/.go"}"
export GOBIN="${GOBIN:-"${GOPATH}/bin"}"
export PATH="${GOBIN}${PATH:+:"${PATH}"}"

# Rust
if [[ -f "${HOME}/.cargo/env" ]]; then
	source "${HOME}/.cargo/env"
fi

# Ruby
export RUBYOPT="-W0"
export PATH="${HOMEBREW_PREFIX}/opt/ruby/bin${PATH:+:"${PATH}"}"
export PATH="$(ruby -r rubygems -e 'puts Gem.dir')/bin${PATH:+:"${PATH}"}"
export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin${PATH:+:"${PATH}"}"

# Perl
eval "$(LC_ALL="C" perl -I"${HOMEBREW_PREFIX}/opt/perl/lib/perl5" -Mlocal::lib="${HOMEBREW_PREFIX}/opt/perl")"

# cURL
export PATH="${HOMEBREW_PREFIX}/opt/curl/bin${PATH:+:"${PATH}"}"

# OpenSSL
export PATH="${HOMEBREW_PREFIX}/opt/openssl/bin${PATH:+:"${PATH}"}"

# gettext
export PATH="${HOMEBREW_PREFIX}/opt/gettext/bin${PATH:+:"${PATH}"}"

# NCURSES
export PATH="${HOMEBREW_PREFIX}/opt/ncurses/bin${PATH:+:"${PATH}"}"
export C_INCLUDE_PATH="${HOMEBREW_PREFIX}/opt/ncurses/include${C_INCLUDE_PATH:+:"${C_INCLUDE_PATH}"}"
export CPLUS_INCLUDE_PATH="${HOMEBREW_PREFIX}/opt/ncurses/include${CPLUS_INCLUDE_PATH:+:"${CPLUS_INCLUDE_PATH}"}"
export LIBRARY_PATH="${HOMEBREW_PREFIX}/opt/ncurses/lib${LIBRARY_PATH:+:"${LIBRARY_PATH}"}"
export DYLD_LIBRARY_PATH="${HOMEBREW_PREFIX}/opt/ncurses/lib${DYLD_LIBRARY_PATH:+:"${DYLD_LIBRARY_PATH}"}"

# SQLite
export PATH="${HOMEBREW_PREFIX}/opt/sqlite/bin${PATH:+:"${PATH}"}"

# LLVM
export PATH="${HOMEBREW_PREFIX}/opt/llvm/bin${PATH:+:"${PATH}"}"

# libarchive
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:+"${DYLD_FALLBACK_LIBRARY_PATH}":}${HOMEBREW_PREFIX}/opt/libarchive/lib"

# Wine
export WINEARCH="win32"
export WINEPREFIX="${HOME}/.wine32"
export WINEDEBUG="-all"
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:+"${DYLD_FALLBACK_LIBRARY_PATH}":}/usr/X11/lib:${HOMEBREW_PREFIX}/lib"

# fzf
if [[ -f "${HOME}/.fzf.zsh" ]]; then
	source "${HOME}/.fzf.zsh"
fi
export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --no-ignore-vcs --exclude '.git' --exclude '[Mm]iniconda3' --exclude '[Aa]naconda3' --color=always"
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
FZF_PREVIEW_COMMAND="(bat --color=always {} || highlight -O ansi {} || cat {}) 2>/dev/null | head -100"
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --ansi --preview='${FZF_PREVIEW_COMMAND}'"

# bat
export BAT_THEME="Monokai Extended"

# iTerm
if [[ -f "${HOME}/.iterm2/.iterm2_shell_integration.zsh" ]]; then
	source "${HOME}/.iterm2/.iterm2_shell_integration.zsh"
fi

# Conda
if [[ -n "${__CONDA_PREFIX}" ]]; then
	conda activate "${__CONDA_PREFIX}"
fi
unset __CONDA_PREFIX

# Remove duplicate entries
function __remove_duplicate() {
	local sep name value
	sep="$1"
	shift
	while [[ $# -gt 0 ]]; do
		name="$1"
		shift
		if [[ -z "${name}" ]]; then
			break
		fi
		value="$(
			eval "printf \"%s%s\" \"\$${name}\" \"${sep}\"" |
				/usr/bin/awk -v RS="${sep}" 'BEGIN { idx = 0; }
				{ if (!(exists[$0]++)) printf("%s%s", (!(idx++) ? "" : RS), $0); }'
		)"
		if [[ -n "${value}" ]]; then
			export "${name}"="${value}"
		else
			unset "${name}"
		fi
	done
}
__remove_duplicate ':' PATH
__remove_duplicate ':' {C,CPLUS}_INCLUDE_PATH
__remove_duplicate ':' {,DYLD_{,FALLBACK_}}LIBRARY_PATH
unset -f __remove_duplicate

# Utilities
if [[ -f "${HOME}/.dotfiles/utilities.sh" ]]; then
	source "${HOME}/.dotfiles/utilities.sh"
	if pgrep ClashX &>/dev/null; then
		set_proxy 127.0.0.1
	fi
fi

# X11
export DISPLAY=":0.0"
xhost +local: &>/dev/null

# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"
ZSH_COMPDUMP="${HOME}/.zcompdump"
HISTFILE="${HOME}/.zsh_history"
DEFAULT_USER="PanXuehai"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo "${RANDOM_THEME}"
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Powerlevel10k configurations
typeset -g POWERLEVEL9K_MODE="nerdfont-complete"
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
typeset -g POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%K{white}%F{black} \ue795 \uf155 %f%k%F{white}\ue0b0%f "
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(virtualenv anaconda pyenv context root_indicator dir dir_writable vcs)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time status background_jobs time ssh)
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY="truncate_to_unique"
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH='75%'
typeset -g GITSTATUS_NUM_THREADS=4
typeset -g POWERLEVEL9K_VCS_PUSH_INCOMING_CHANGES_ICON='\uf0a8 '
typeset -g POWERLEVEL9K_VCS_PUSH_OUTGOING_CHANGES_ICON='\uf0a9 '
typeset -g POWERLEVEL9K_VCS_SHORTEN_DELIMITER="…"
typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1
typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1
typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'
# Formatter for Git status.
#
# Example output: master wip ⇣42⇡42 *42 merge ~42 +42 !42 ?42.
#
# VCS_STATUS_* parameters are set by gitstatus plugin. See reference:
# https://github.com/romkatv/gitstatus/blob/master/gitstatus.plugin.zsh.
function _p9k_gitstatus_formatter() {
	emulate -L zsh

	if [[ -n "${P9K_CONTENT}" ]]; then
		# If P9K_CONTENT is not empty, use it. It's either "loading" or from vcs_info (not from
		# gitstatus plugin). VCS_STATUS_* parameters are not available in this case.
		_p9k_gitstatus_format="${P9K_CONTENT}"
		return
	fi

	# Styling for different parts of Git status.
	local       meta='%7F' # white foreground
	local      clean='%0F' # black foreground
	local   modified='%0F' # black foreground
	local  untracked='%0F' # black foreground
	local conflicted='%1F' # red foreground

	local res="${meta}${clean}$(print_icon VCS_COMMIT_ICON)${VCS_STATUS_COMMIT[1,6]}"

	if [[ -n "${VCS_STATUS_LOCAL_BRANCH}" ]]; then
		local branch="${(V)VCS_STATUS_LOCAL_BRANCH}"
		# If local branch name is at most 9 characters long, show it in full.
		# Otherwise show the first 4 … the last 4.
		(( ${#branch} > 9 )) && branch[5,-5]="${(g::)POWERLEVEL9K_VCS_SHORTEN_DELIMITER}"
		res+=" ${clean}$(print_icon VCS_BRANCH_ICON)${branch//\%/%%}"
	fi

	if [[ -n "${VCS_STATUS_TAG}" ]]; then
		local tag="${(V)VCS_STATUS_TAG}"
		(( ${#tag} > 9 )) && tag[5,-5]="${(g::)POWERLEVEL9K_VCS_SHORTEN_DELIMITER}"
		res+=" ${meta}$(print_icon VCS_TAG_ICON)${clean}${tag//\%/%%}"
	fi

	# Show tracking branch name if it differs from local branch.
	if [[ -n "${VCS_STATUS_REMOTE_BRANCH:#"${VCS_STATUS_LOCAL_BRANCH}"}" ]]; then
		res+=" ${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"
	fi

	# Display "wip" if the latest commit's summary contains "wip" or "WIP".
	if [[ "${VCS_STATUS_COMMIT_SUMMARY}" == (|*[^[:alnum:]])(wip|WIP)(|[^[:alnum:]]*) ]]; then
		res+=" ${modified}wip"
	fi

	# ⇣42 if behind the remote.
	(( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}$(print_icon VCS_INCOMING_CHANGES_ICON)${VCS_STATUS_COMMITS_BEHIND}"
	# ⇡42 if ahead of the remote.
	(( VCS_STATUS_COMMITS_AHEAD  )) && res+=" ${clean}$(print_icon VCS_OUTGOING_CHANGES_ICON)${VCS_STATUS_COMMITS_AHEAD}"
	# ⇠42 if behind the push remote.
	(( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" ${clean}$(print_icon VCS_PUSH_INCOMING_CHANGES_ICON)${VCS_STATUS_PUSH_COMMITS_BEHIND}"
	# ⇢42 if ahead of the push remote.
	(( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+=" ${clean}$(print_icon VCS_PUSH_OUTGOING_CHANGES_ICON)${VCS_STATUS_PUSH_COMMITS_AHEAD}"
	# *42 if have stashes.
	(( VCS_STATUS_STASHES        )) && res+=" ${clean}$(print_icon VCS_STASH_ICON)${VCS_STATUS_STASHES}"
	# 'merge' if the repo is in an unusual state.
	[[ -n "${VCS_STATUS_ACTION}" ]] && res+=" ${conflicted}${VCS_STATUS_ACTION//\%/%%}"
	# ~42 if have merge conflicts.
	(( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}${VCS_STATUS_NUM_CONFLICTED}"
	# +42 if have staged changes.
	(( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}$(print_icon VCS_STAGED_ICON)${VCS_STATUS_NUM_STAGED}"
	# !42 if have unstaged changes.
	(( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}$(print_icon VCS_UNSTAGED_ICON)${VCS_STATUS_NUM_UNSTAGED}"
	(( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}$(print_icon VCS_UNTRACKED_ICON)${VCS_STATUS_NUM_UNTRACKED}"
	(( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${modified}─"

	_p9k_gitstatus_format="${res}"
}
functions -M _p9k_gitstatus_formatter 2>/dev/null
typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((_p9k_gitstatus_formatter()))+${_p9k_gitstatus_format}}'

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ${ZSH}/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than ${ZSH}/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ${ZSH}/plugins/
# Custom plugins may be added to ${ZSH_CUSTOM}/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	macos
	zsh-syntax-highlighting
	zsh-autosuggestions
	zsh-completions
	conda-zsh-completion
	colorize
	colored-man-pages
	fzf
	copyfile
	copypath
	cp
	rsync
	alias-finder
	git
	git-auto-fetch
	python
	pip
	rust
	docker
	tmux
	brew
	vscode
)

ZSH_COLORIZE_STYLE="monokai"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

source "${ZSH}/oh-my-zsh.sh"

# User configuration

# export MANPATH="/usr/local/man${MANPATH:+:"${MANPATH}"}"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n "${SSH_CONNECTION}" ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the ${ZSH_CUSTOM} folder, with .zsh extension. Examples:
# - ${ZSH_CUSTOM}/aliases.zsh
# - ${ZSH_CUSTOM}/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set personal aliases
alias bubo='brew update --verbose && brew outdated'
alias bubc='brew upgrade && brew cleanup -s --prune 7'
alias lsa='ls -A'
alias l='ls -alh'
alias ll='ls -lh'
alias la='ls -Alh'

if [[ -z "${P10K_LEAN_STYLE}" ]]; then
	# Setup Color LS
	source "$(dirname "$(gem which colorls)")"/tab_complete.sh
	alias ls='colorls --sort-dirs --git-status'
else
	# Use Powerlevel10k Lean style
	source "${ZSH_CUSTOM}/themes/powerlevel10k/config/p10k-lean.zsh"
	POWERLEVEL9K_MODE="compatible"
	POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(virtualenv anaconda pyenv context root_indicator dir vcs newline prompt_char)
	POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time ssh)
	POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='·'
	POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=' '
	POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=' '
	POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_FIRST_SEGMENT_END_SYMBOL='%{%}'
	POWERLEVEL9K_EMPTY_LINE_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL='%{%}'
	POWERLEVEL9K_STATUS_ERROR=true
	POWERLEVEL9K_ANACONDA_SHOW_PYTHON_VERSION=true
	POWERLEVEL9K_ANACONDA_CONTENT_EXPANSION='${P9K_CONTENT}'
	POWERLEVEL9K_ANACONDA_LEFT_DELIMITER='('
	POWERLEVEL9K_ANACONDA_RIGHT_DELIMITER=')'
	POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=true
	POWERLEVEL9K_PYENV_CONTENT_EXPANSION='${P9K_CONTENT}'
	POWERLEVEL9K_VIRTUALENV_LEFT_DELIMITER='('
	POWERLEVEL9K_VIRTUALENV_RIGHT_DELIMITER=')'
	p10k reload
fi
