# ~/.bash_profile: executed by bash for login shells.

# Get the aliases and functions
# Source global definitions
# Include /etc/profile if it exists
if [[ -f /etc/profile ]]; then
	source /etc/profile
fi

# If running bash as login shell
if [[ -n "$BASH_VERSION" ]] && shopt -q login_shell; then
	# Include ~/.bashrc if it exists
	if [[ -f "$HOME/.bashrc" ]]; then
		source "$HOME/.bashrc"
	fi
fi

# Set PATH so it includes user's private bin if it exists
if [[ -d "$HOME/.local/bin" ]]; then
	export PATH="$HOME/.local/bin${PATH:+:"$PATH"}"
fi

# Set C_INCLUDE_PATH and CPLUS_INCLUDE_PATH so it includes user's private include if it exists
if [[ -d "$HOME/.local/include" ]]; then
	export C_INCLUDE_PATH="$HOME/.local/include${C_INCLUDE_PATH:+:"$C_INCLUDE_PATH"}"
	export CPLUS_INCLUDE_PATH="$HOME/.local/include${CPLUS_INCLUDE_PATH:+:"$CPLUS_INCLUDE_PATH"}"
fi

# Set LIBRARY_PATH and DYLD_LIBRARY_PATH so it includes user's private lib if it exists
if [[ -d "$HOME/.local/lib" ]]; then
	export LIBRARY_PATH="$HOME/.local/lib${LIBRARY_PATH:+:"$LIBRARY_PATH"}"
	export DYLD_LIBRARY_PATH="$HOME/.local/lib${DYLD_LIBRARY_PATH:+:"$DYLD_LIBRARY_PATH"}"
fi
if [[ -d "$HOME/.local/lib64" ]]; then
	export LIBRARY_PATH="$HOME/.local/lib64${LIBRARY_PATH:+:"$LIBRARY_PATH"}"
	export DYLD_LIBRARY_PATH="$HOME/.local/lib64${DYLD_LIBRARY_PATH:+:"$DYLD_LIBRARY_PATH"}"
fi

# User specific environment
export TERM="xterm-256color"
export LESS="-R -M -i -j5"
export GREP_OPTIONS='--color=auto'
export CLICOLOR=1
export LSCOLORS="GxFxCxDxBxegedabagaced"
if [[ -n "$SSH_CONNECTION" ]]; then
	export PS1='[\[\e[1;33m\]\u\[\e[0m\]@\[\e[1;32m\]\h\[\e[0m\]:\[\e[1;35m\]\w\[\e[0m\]]\$ '
else
	export PS1='[\[\e[1;33m\]\u\[\e[0m\]:\[\e[1;35m\]\w\[\e[0m\]]\$ '
fi

# Locale
export LC_ALL="en_US.UTF-8"

# Homebrew
eval "$(/usr/local/bin/brew shellenv)"
export HOMEBREW_EDITOR="vim"
export HOMEBREW_BAT=true
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/bottles"

# Anaconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$(CONDA_REPORT_ERRORS=false "$HOME/Miniconda3/bin/conda" shell.bash hook 2>/dev/null)"
if [[ $? -eq 0 ]]; then
	eval "$__conda_setup"
else
	if [[ -f "$HOME/Miniconda3/etc/profile.d/conda.sh" ]]; then
		source "$HOME/Miniconda3/etc/profile.d/conda.sh"
	else
		export PATH="$HOME/Miniconda3/bin${PATH:+:"$PATH"}"
	fi
fi
unset __conda_setup
# <<< conda initialize <<<
export CONDA_JL_HOME="$HOME/Miniconda3/envs/python38"

# CXX Compilers
export CC="$HOMEBREW_PREFIX/bin/gcc-11"
export CXX="$HOMEBREW_PREFIX/bin/g++-11"
export FC="$HOMEBREW_PREFIX/bin/gfortran-11"
export OMPI_CC="$CC" MPICH_CC="$CC"
export OMPI_CXX="$CXX" MPICH_CXX="$CXX"
export OMPI_FC="$FC" MPICH_FC="$FC"

# Java
export JAVA_HOME="$(/usr/libexec/java_home)"
export CLASSPATH=".:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar"
export PATH="$JAVA_HOME/bin${PATH:+:"$PATH"}"

# Go
export GOPATH="$HOMEBREW_PREFIX/opt/go"
export GOBIN="$GOPATH/bin"
export GOROOT="$GOPATH/libexec"
export PATH="$GOBIN${PATH:+:"$PATH"}"

# Ruby
export RUBYOPT="-W0"
export PATH="$HOMEBREW_PREFIX/opt/ruby/bin${PATH:+:"$PATH"}"
export PATH="$(ruby -r rubygems -e 'puts Gem.dir')/bin${PATH:+:"$PATH"}"
export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin${PATH:+:"$PATH"}"

# Perl
eval "$(perl -I"$HOMEBREW_PREFIX/opt/perl/lib/perl5" -Mlocal::lib="$HOMEBREW_PREFIX/opt/perl")"

# Mono
export MONO_GAC_PREFIX="$HOMEBREW_PREFIX"

# Qt
export PATH="$HOMEBREW_PREFIX/opt/qt/bin${PATH:+:"$PATH"}"

# cURL
export PATH="$HOMEBREW_PREFIX/opt/curl/bin${PATH:+:"$PATH"}"

# OpenSSL
export PATH="$HOMEBREW_PREFIX/opt/openssl/bin${PATH:+:"$PATH"}"

# gettext
export PATH="$HOMEBREW_PREFIX/opt/gettext/bin${PATH:+:"$PATH"}"

# Bison
export PATH="$HOMEBREW_PREFIX/opt/bison/bin${PATH:+:"$PATH"}"

# NCURSES
export PATH="$HOMEBREW_PREFIX/opt/ncurses/bin${PATH:+:"$PATH"}"
export C_INCLUDE_PATH="$HOMEBREW_PREFIX/opt/ncurses/include${C_INCLUDE_PATH:+:"$C_INCLUDE_PATH"}"
export CPLUS_INCLUDE_PATH="$HOMEBREW_PREFIX/opt/ncurses/include${CPLUS_INCLUDE_PATH:+:"$CPLUS_INCLUDE_PATH"}"
export LIBRARY_PATH="$HOMEBREW_PREFIX/opt/ncurses/lib${LIBRARY_PATH:+:"$LIBRARY_PATH"}"
export DYLD_LIBRARY_PATH="$HOMEBREW_PREFIX/opt/ncurses/lib${DYLD_LIBRARY_PATH:+:"$DYLD_LIBRARY_PATH"}"

# SQLite
export PATH="$HOMEBREW_PREFIX/opt/sqlite/bin${PATH:+:"$PATH"}"

# LLVM
export PATH="$HOMEBREW_PREFIX/opt/llvm/bin${PATH:+:"$PATH"}"

# Wine
export WINEARCH="win32"
export WINEPREFIX="$HOME/.wine32"
export WINEDEBUG="-all"
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:+"$DYLD_FALLBACK_LIBRARY_PATH":}/usr/X11/lib:$HOMEBREW_PREFIX/lib"
export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH:+"$DYLD_FALLBACK_LIBRARY_PATH":}$HOMEBREW_PREFIX/opt/ncurses/lib"

# fzf
if [[ -f "$HOME/.fzf.bash" ]]; then
	source "$HOME/.fzf.bash"
fi
export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --no-ignore-vcs --exclude '.git' --exclude '[Mm]iniconda3' --exclude '[Aa]naconda3' --color=always"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
FZF_PREVIEW_COMMAND="(bat --color=always {} || highlight -O ansi {} || cat {}) 2>/dev/null | head -100"
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --ansi --preview='${FZF_PREVIEW_COMMAND}'"

# bat
export BAT_THEME="Monokai Extended"

# iTerm
if [[ -f "$HOME/.iterm2/.iterm2_shell_integration.bash" ]]; then
	source "$HOME/.iterm2/.iterm2_shell_integration.bash"
fi

# Remove duplicate entries
function __remove_duplicate() {
	local SEP="$1" NAME="$2" VALUE
	VALUE="$(
		eval "printf \"%s%s\" \"\$$NAME\" \"$SEP\"" |
			/usr/bin/awk -v RS="$SEP" 'BEGIN { idx = 0; }
				{ if (!(exists[$0]++)) printf("%s%s", (!(idx++) ? "" : RS), $0); }'
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
	source "$HOME/.dotfiles/utilities.sh"
	if pgrep ClashX &>/dev/null; then
		set_proxy 127.0.0.1
	fi
fi

# X11
export DISPLAY=":0.0"
xhost +local: &>/dev/null

# Bash completion
if [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]]; then
	source "/usr/local/etc/profile.d/bash_completion.sh"
fi
