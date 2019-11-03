# .bash_profile

# Get the aliases and functions
# Source global definitions
# include /etc/profile if it exists
if [ -f /etc/profile ]; then
	. /etc/profile
fi

# include ~/.bashrc if it exists
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
	export PATH="$HOME/.local/bin:$PATH"
fi

# set C_INCLUDE_PATH and CPLUS_INCLUDE_PATH so it includes user's private include if it exists
if [ -d "$HOME/.local/include" ]; then
	export C_INCLUDE_PATH="$HOME/.local/include:$C_INCLUDE_PATH"
	export CPLUS_INCLUDE_PATH="$HOME/.local/include:$CPLUS_INCLUDE_PATH"
fi

# set LIBRARY_PATH and DYLD_LIBRARY_PATH so it includes user's private lib if it exists
if [ -d "$HOME/.local/lib" ]; then
	export LIBRARY_PATH="$HOME/.local/lib:$LIBRARY_PATH"
	export DYLD_LIBRARY_PATH="$HOME/.local/lib:$DYLD_LIBRARY_PATH"
fi

# set MANPATH so it includes user's private man if it exists
if [ -d "$HOME/.local/man" ]; then
	export MANPATH="$HOME/.local/man:$MANPATH"
fi

# User specific environment and startup programs
export TERM="xterm-256color"
export PS1='[\[\e[1;33m\]\u\[\e[0m\]@\[\e[1;32m\]\h\[\e[0m\]:\[\e[1;35m\]\W\[\e[0m\]]\$ '

# locale
export LANG="en_US.UTF-8"

# Compilers
export CC="/usr/bin/gcc"
export CXX="/usr/bin/g++"
export FC="/usr/local/bin/gfortran"
export OMPI_CC="$CC"
export OMPI_CXX="$CXX"
export OMPI_FC="$FC"

# Homebrew
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

# Anaconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$HOME/Anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/Anaconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/Anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/Anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
export CONDA_JL_HOME="$HOME/Anaconda3/envs/python37"

# Intel
source "/opt/intel/bin/compilervars.sh" -arch intel64 -platform mac

# Java
export JAVA_HOME=$(/usr/libexec/java_home)
export CLASSPATH=".:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar"
export PATH="$JAVA_HOME/bin:$PATH"

# Perl
eval "$(perl -I/usr/local/opt/perl/lib/perl5 -Mlocal::lib=/usr/local/opt/perl)"

# Go
export GOPATH="/usr/local/opt/go"
export GOBIN="$GOPATH/bin"
export GOROOT="$GOPATH/libexec"
export GOPATH="$HOME/GolandProjects:$GOPATH"
export PATH="$GOBIN:$PATH"

# Haskell-Stack
export PATH="$(stack path --bin-path)"

# Mono
export MONO_GAC_PREFIX="/usr/local"

# Ruby
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="$(ruby -r rubygems -e 'puts Gem.dir')/bin:$PATH"
export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"

# Qt
export PATH="/usr/local/opt/qt/bin:$PATH"

# Texinfo
export PATH="/usr/local/opt/texinfo/bin:$PATH"

# Curl
export PATH="/usr/local/opt/curl/bin:$PATH"

# OpenSSL
export PATH="/usr/local/opt/openssl/bin:$PATH"

# APR-util
export PATH="/usr/local/opt/apr-util/bin:$PATH"

# gettext
export PATH="/usr/local/opt/gettext/bin:$PATH"

# ncurses
export PATH="/usr/local/opt/ncurses/bin:$PATH"

# SQLite
export PATH="/usr/local/opt/sqlite/bin:$PATH"

# LLVM
export PATH="/usr/local/opt/llvm/bin:$PATH"

# MySQL
export PATH="/usr/local/mysql/bin:$PATH"

# Wine
export WINEARCH="win32"
export WINEPREFIX="$HOME/.wine32"
export WINEDEBUG="-all"
export DYLD_FALLBACK_LIBRARY_PATH="$DYLD_FALLBACK_LIBRARY_PATH:/usr/X11/lib:/usr/local/lib"
export DYLD_FALLBACK_LIBRARY_PATH="$DYLD_FALLBACK_LIBRARY_PATH:/usr/local/opt/ncurses/lib"

# Remove duplicate entries
function remove_duplicate() {
	for item in "$@"; do
		echo $(printf "%s" "$item" | awk -v RS=':' 'BEGIN { idx = 0; delete flag; } { if (!(flag[$0]++)) { printf("%s%s", (!idx++ ? "" : ":"), $0) } }')
	done
}
export PATH=$(remove_duplicate $PATH)
export C_INCLUDE_PATH=$(remove_duplicate $C_INCLUDE_PATH)
export CPLUS_INCLUDE_PATH=$(remove_duplicate $CPLUS_INCLUDE_PATH)
export LIBRARY_PATH=$(remove_duplicate $LIBRARY_PATH)
export DYLD_LIBRARY_PATH=$(remove_duplicate $DYLD_LIBRARY_PATH)
export DYLD_FALLBACK_LIBRARY_PATH=$(remove_duplicate $DYLD_FALLBACK_LIBRARY_PATH)
export CLASSPATH=$(remove_duplicate $CLASSPATH)
export MANPATH=$(remove_duplicate $MANPATH)
unset -f remove_duplicate

# X11
export DISPLAY=":0.0"
xhost +local: &>/dev/null