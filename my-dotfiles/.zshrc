# Source global definitions
# Include /etc/zshrc if it exists
if [[ -f /etc/zshrc ]]; then
	. /etc/zshrc
fi

# Include /etc/profile if it exists
if [[ -f /etc/profile ]]; then
	. /etc/profile
fi

# Include /etc/zprofile if it exists
if [[ -f /etc/zprofile ]]; then
	. /etc/zprofile
fi

# Set PATH so it includes user's private bin if it exists
if [[ -d "$HOME/.local/bin" ]]; then
	export PATH="$HOME/.local/bin:$PATH"
fi

# Set C_INCLUDE_PATH and CPLUS_INCLUDE_PATH so it includes user's private include if it exists
if [[ -d "$HOME/.local/include" ]]; then
	export C_INCLUDE_PATH="$HOME/.local/include:$C_INCLUDE_PATH"
	export CPLUS_INCLUDE_PATH="$HOME/.local/include:$CPLUS_INCLUDE_PATH"
fi

# Set LIBRARY_PATH and DYLD_LIBRARY_PATH so it includes user's private lib if it exists
if [[ -d "$HOME/.local/lib" ]]; then
	export LIBRARY_PATH="$HOME/.local/lib:$LIBRARY_PATH"
	export DYLD_LIBRARY_PATH="$HOME/.local/lib:$DYLD_LIBRARY_PATH"
fi
if [[ -d "$HOME/.local/lib64" ]]; then
	export LIBRARY_PATH="$HOME/.local/lib64:$LIBRARY_PATH"
	export DYLD_LIBRARY_PATH="$HOME/.local/lib64:$DYLD_LIBRARY_PATH"
fi

# User specific environment
export TERM="xterm-256color"
export CLICOLOR=1
export LSCOLORS="GxFxCxDxBxegedabagaced"

# Locale
export LC_ALL="en_US.UTF-8"

# Compilers
export CC="/usr/local/bin/gcc-10"
export CXX="/usr/local/bin/g++-10"
export FC="/usr/local/bin/gfortran-10"
export OMPI_CC="$CC" MPICH_CC="$CC"
export OMPI_CXX="$CXX" MPICH_CXX="$CXX"
export OMPI_FC="$FC" MPICH_FC="$FC"

# Homebrew
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_EDITOR="vim"
export HOMEBREW_BAT=true

# Anaconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$(CONDA_REPORT_ERRORS=false "$HOME/Miniconda3/bin/conda" shell.zsh hook 2>/dev/null)"
if [[ $? -eq 0 ]]; then
	eval "$__conda_setup"
else
	if [[ -f "$HOME/Miniconda3/etc/profile.d/conda.sh" ]]; then
		. "$HOME/Miniconda3/etc/profile.d/conda.sh"
	else
		export PATH="$HOME/Miniconda3/bin:$PATH"
	fi
fi
unset __conda_setup
# <<< conda initialize <<<
export CONDA_JL_HOME="$HOME/Miniconda3/envs/python37"

# Java
export JAVA_HOME="$(/usr/libexec/java_home)"
export CLASSPATH=".:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar"
export PATH="$JAVA_HOME/bin:$PATH"

# Go
export GOPATH="/usr/local/opt/go"
export GOBIN="$GOPATH/bin"
export GOROOT="$GOPATH/libexec"
export PATH="$GOBIN:$PATH"

# Ruby
export RUBYOPT="-W0"
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="$(ruby -r rubygems -e 'puts Gem.dir')/bin:$PATH"
export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"

# Perl
eval "$(perl -I/usr/local/opt/perl/lib/perl5 -Mlocal::lib=/usr/local/opt/perl)"

# Mono
export MONO_GAC_PREFIX="/usr/local"

# Qt
export PATH="/usr/local/opt/qt/bin:$PATH"

# cURL
export PATH="/usr/local/opt/curl/bin:$PATH"

# OpenSSL
export PATH="/usr/local/opt/openssl/bin:$PATH"

# gettext
export PATH="/usr/local/opt/gettext/bin:$PATH"

# Bison
export PATH="/usr/local/opt/bison/bin:$PATH"

# NCURSES
export PATH="/usr/local/opt/ncurses/bin:$PATH"
export C_INCLUDE_PATH="/usr/local/opt/ncurses/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="/usr/local/opt/ncurses/include:$CPLUS_INCLUDE_PATH"
export LIBRARY_PATH="/usr/local/opt/ncurses/lib:$LIBRARY_PATH"
export DYLD_LIBRARY_PATH="/usr/local/opt/ncurses/lib:$DYLD_LIBRARY_PATH"

# SQLite
export PATH="/usr/local/opt/sqlite/bin:$PATH"

# LLVM
export PATH="/usr/local/opt/llvm/bin:$PATH"

# Wine
export WINEARCH="win32"
export WINEPREFIX="$HOME/.wine32"
export WINEDEBUG="-all"
export DYLD_FALLBACK_LIBRARY_PATH="$DYLD_FALLBACK_LIBRARY_PATH:/usr/X11/lib:/usr/local/lib"
export DYLD_FALLBACK_LIBRARY_PATH="$DYLD_FALLBACK_LIBRARY_PATH:/usr/local/opt/ncurses/lib"

# fzf
if [[ -f "$HOME/.fzf.zsh" ]]; then
	source "$HOME/.fzf.zsh"
fi
export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --no-ignore-vcs --exclude '.git' --color=always"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
FZF_PREVIEW_COMMAND="(bat --color=always {} || highlight -O ansi {} || cat {}) 2>/dev/null | head -100"
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --ansi --preview='${FZF_PREVIEW_COMMAND}'"

# bat
export BAT_THEME="Monokai Extended"

# iTerm
if [[ -f "$HOME/.iterm2/.iterm2_shell_integration.zsh" ]]; then
	source "$HOME/.iterm2/.iterm2_shell_integration.zsh"
fi

# Remove duplicate entries
function __remove_duplicate() {
	local SEP NAME VALUE
	SEP="$1"
	NAME="$2"
	VALUE="$(
		eval "printf \"%s\" \"\$$NAME\"" | awk -v RS="$SEP" \
			'BEGIN {
				idx = 0;
				delete flag;
				flag[""] = 1;
			}
			{
				if (!(flag[$0]++))
					printf("%s%s", (!(idx++) ? "" : RS), $0);
			}'
	)"
	if [[ -n "$VALUE" ]]; then
		export "$NAME"="$VALUE"
	else
		unset "$NAME"
	fi
}
__remove_duplicate ':' PATH
__remove_duplicate ':' C_INCLUDE_PATH
__remove_duplicate ':' CPLUS_INCLUDE_PATH
__remove_duplicate ':' LIBRARY_PATH
__remove_duplicate ':' DYLD_LIBRARY_PATH
__remove_duplicate ':' DYLD_FALLBACK_LIBRARY_PATH
__remove_duplicate ':' CLASSPATH
unset -f __remove_duplicate

# Utilities
if [[ -f "$HOME/.dotfiles/utilities.sh" ]]; then
	. "$HOME/.dotfiles/utilities.sh"
	if pgrep ClashX &>/dev/null; then
		set_proxy 127.0.0.1
	fi
fi

# X11
export DISPLAY=":0.0"
xhost +local: &>/dev/null

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_COMPDUMP="$HOME/.zcompdump"
HISTFILE="$HOME/.zsh_history"
DEFAULT_USER="PanXuehai"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Powerlevel10k configrations
POWERLEVEL9K_MODE="nerdfont-complete"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%K{white}%F{black} \ue795 \uf155 %f%k%F{white}\ue0b0%f "
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(virtualenv anaconda pyenv context root_indicator dir dir_writable vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time status background_jobs time ssh)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_SHOW_CHANGESET=true
POWERLEVEL9K_CHANGESET_HASH_LENGTH=6
POWERLEVEL9K_VCS_SHORTEN_LENGTH=4
POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH=9
POWERLEVEL9K_VCS_SHORTEN_STRATEGY="truncate_middle"
GITSTATUS_NUM_THREADS=4

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
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

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	osx
	zsh-syntax-highlighting
	zsh-autosuggestions
	zsh-completions
	colorize
	colored-man-pages
	fd
	fzf
	copyfile
	copydir
	cp
	rsync
	alias-finder
	git
	git-auto-fetch
	python
	pip
	pylint
	docker
	tmux
	brew
	vscode
)

ZSH_COLORIZE_STYLE="monokai"
ZSH_DISABLE_COMPFIX=true

source "$ZSH/oh-my-zsh.sh"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n "$SSH_CONNECTION" ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# SSH
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run $(alias).
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

if [[ -z "$P10K_LEAN_STYLE" ]]; then
	# Setup Color LS
	source "$(dirname "$(gem which colorls)")"/tab_complete.sh
	alias ls='colorls --sort-dirs --git-status'
else
	# Use Powerlevel10k Lean style
	source "$ZSH_CUSTOM/themes/powerlevel10k/config/p10k-lean.zsh"
	POWERLEVEL9K_MODE="compatible"
	POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
	POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs virtualenv anaconda pyenv time)
	POWERLEVEL9K_TRANSIENT_PROMPT="same-dir"
	POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='·'
	POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=' '
	POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=' '
	POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_FIRST_SEGMENT_END_SYMBOL='%{%}'
	POWERLEVEL9K_EMPTY_LINE_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL='%{%}'
	unset P10K_LEAN_STYLE
	p10k reload
fi
