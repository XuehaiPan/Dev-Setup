#!/usr/bin/env bash

DATETIME=$(date +"%Y-%m-%d-%T")
BACKUP_DIR=".dotfiles/backups/$DATETIME"
mkdir -p "$BACKUP_DIR/.dotfiles"

IS_WSL=false
if $(uname -r | grep -qF 'Microsoft'); then
	IS_WSL=true
fi

function echo_and_eval() {
	local CMD="$*"
	printf "%s" "$CMD" | awk \
		'BEGIN {
			BoldGreen="\033[1;32m";
			BoldYellow="\033[1;33m";
			BoldWhite="\033[1;37m";
			Reset="\033[0m";
			printf("%s$%s", BoldWhite, Reset);
		}
		{
			for (i = 1; i <= NF; ++i) {
				Style = BoldWhite;
				if ($i ~ /^-/) {
					Style = BoldYellow;
				} else if (i == 1 || $i == "sudo" || $(i - 1) == "sudo") {
					Style = BoldGreen;
				}
				printf(" %s%s%s", Style, $i, Reset);
			}
		}
		END {
			printf("\n");
		}'
	eval "$CMD"
}

function backup_dotfiles() {
	for file in "$@"; do
		if [[ -f $file ]] || [[ -d $file ]]; then
			if [[ -L $file ]]; then
				local original_file=$(readlink "$file")
				rm -f "$file"
				cp -rf "$original_file" "$file"
			fi
			cp -rf "$file" "$BACKUP_DIR/$file"
		fi
	done
}

for repo in "arch4edu" "archlinuxcn"; do
	if ! grep -qF "[$repo]" /etc/pacman.conf; then
		echo_and_eval 'printf "\n%s\n%s\n" "[$repo]" "Server = https://mirrors.tuna.tsinghua.edu.cn/$repo/\$arch" \
					   | sudo tee -a /etc/pacman.conf'
	fi
done

sudo sed -i -e 's/^\s*#\s*Color$/Color/g' /etc/pacman.conf
sudo sed -i -e 's/^\s*#\s*DisableDownloadTimeout$/DisableDownloadTimeout/g' /etc/pacman.conf
if ! grep -q '^DisableDownloadTimeout$' /etc/pacman.conf; then
	sudo sed -i -e 's/^Color$/Color\nDisableDownloadTimeout/g' /etc/pacman.conf
fi

echo_and_eval 'sudo pacman -Syy'
echo_and_eval 'sudo pacman-key --recv-keys 7931B6D628C8D3BA'
echo_and_eval 'sudo pacman-key --finger 7931B6D628C8D3BA'
echo_and_eval 'sudo pacman-key --lsign-key 7931B6D628C8D3BA'
echo_and_eval 'sudo pacman -S archlinuxcn-keyring --noconfirm'

echo_and_eval 'sudo pacman-mirrors --country China --method rank'

echo_and_eval 'sudo pacman -Syy'

echo_and_eval 'sudo pacman -S zsh --noconfirm'

if ! grep -qF '/usr/bin/zsh' /etc/shells; then
	echo_and_eval 'echo "/usr/bin/zsh" | sudo tee -a /etc/shells'
fi

if [[ $SHELL != "/usr/bin/zsh" ]]; then
	echo_and_eval 'chsh -s /usr/bin/zsh'
fi

echo_and_eval 'sudo pacman -S wget curl git git-lfs --noconfirm'
echo_and_eval 'sudo pacman -S vim tmux htop openssh net-tools exfat-utils xclip --noconfirm'
echo_and_eval 'sudo pacman -S gcc gdb clang llvm lldb make cmake ruby --noconfirm'

echo_and_eval 'sudo pacman -Syy'
echo_and_eval 'sudo pacman -Syu --noconfirm'
echo_and_eval 'sudo pacman -Scc --noconfirm'
echo_and_eval 'sudo paccache -ruk0'

echo_and_eval 'systemctl start sshd'
echo_and_eval 'systemctl enable sshd.service'

export ZSH=${ZSH:-$HOME/.oh-my-zsh}
export ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH/custom}
export CHSH=${CHSH:-no}
export RUNZSH=${RUNZSH:-no}

echo_and_eval 'sh -c "$(wget -O- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"'

echo_and_eval 'git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k'

for plugin in zsh-syntax-highlighting zsh-autosuggestions zsh-completions; do
	echo_and_eval "git clone https://github.com/zsh-users/$plugin \$ZSH_CUSTOM/plugins/$plugin"
done

rm -f $HOME/.zcompdump* 2>/dev/null
rm -f $HOME/.shell.pre-oh-my-zsh 2>/dev/null

echo_and_eval 'cd $HOME'

mkdir -p .dotfiles

backup_dotfiles .gemrc .dotfiles/.gemrc

cat >.dotfiles/.gemrc <<EOF
---
:backtrace: false
:bulk_threshold: 1000
:sources:
- https://mirrors.tuna.tsinghua.edu.cn/rubygems/
:update_sources: true
:verbose: true
:concurrent_downloads: 8
EOF

ln -sf .dotfiles/.gemrc .

export PATH="$(ruby -r rubygems -e 'puts Gem.dir')/bin:$PATH"
export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
echo_and_eval 'gem update --system'
echo_and_eval 'gem update'
echo_and_eval 'gem install colorls'
echo_and_eval 'gem cleanup'

backup_dotfiles .dotfiles/.zshrc-common

cat >.dotfiles/.zshrc-common <<EOF
# Source global definitions
# include /etc/zshrc if it exists
if [ -f /etc/zshrc ]; then
	. /etc/zshrc
fi

# include /etc/profile if it exists
if [ -f /etc/profile ]; then
	. /etc/profile
fi

# include /etc/zprofile if it exists
if [ -f /etc/zprofile ]; then
	. /etc/zprofile
fi

# set PATH so it includes user's private bin if it exists
if [ -d "\$HOME/.local/bin" ]; then
	export PATH="\$HOME/.local/bin:\$PATH"
fi

# set C_INCLUDE_PATH and CPLUS_INCLUDE_PATH so it includes user's private include if it exists
if [ -d "\$HOME/.local/include" ]; then
	export C_INCLUDE_PATH="\$HOME/.local/include:\$C_INCLUDE_PATH"
	export CPLUS_INCLUDE_PATH="\$HOME/.local/include:\$CPLUS_INCLUDE_PATH"
	export INCLUDE_PATH="\$HOME/.local/include:\$INCLUDE_PATH"
fi

# set LIBRARY_PATH and LD_LIBRARY_PATH so it includes user's private lib if it exists
if [ -d "\$HOME/.local/lib" ]; then
	export LIBRARY_PATH="\$HOME/.local/lib:\$LIBRARY_PATH"
	export LD_LIBRARY_PATH="\$HOME/.local/lib:\$LD_LIBRARY_PATH"
fi

# set MANPATH so it includes user's private man if it exists
if [ -d "\$HOME/.local/man" ]; then
	export MANPATH="\$HOME/.local/man:\$MANPATH"
fi

# User specific environment and startup programs
export TERM="xterm-256color"

# locale
export LANG="en_US.utf8"

# Compilers
export CC="/usr/bin/gcc"
export CXX="/usr/bin/g++"
export FC="/usr/bin/gfortran"
export OMPI_CC="\$CC"
export OMPI_CXX="\$CXX"
export OMPI_FC="\$FC"

# Anaconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="\$('\$HOME/Miniconda3/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
if [ \$? -eq 0 ]; then
	eval "\$__conda_setup"
else
	if [ -f "\$HOME/Miniconda3/etc/profile.d/conda.sh" ]; then
		. "\$HOME/Miniconda3/etc/profile.d/conda.sh"
	else
		export PATH="\$HOME/Miniconda3/bin:\$PATH"
	fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Ruby
export PATH="\$(ruby -r rubygems -e 'puts Gem.dir')/bin:\$PATH"
export PATH="\$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:\$PATH"

# Remove duplicate entries
function remove_duplicate() {
	for item in "\$@"; do
		echo \$(printf "%s" "\$item" | awk -v RS=':' 'BEGIN { idx = 0; delete flag; } { if (!(flag[\$0]++)) { printf("%s%s", (!idx++ ? "" : ":"), \$0); } }')
	done
}
export PATH=\$(remove_duplicate \$PATH)
export C_INCLUDE_PATH=\$(remove_duplicate \$C_INCLUDE_PATH)
export CPLUS_INCLUDE_PATH=\$(remove_duplicate \$CPLUS_INCLUDE_PATH)
export INCLUDE_PATH=\$(remove_duplicate \$INCLUDE_PATH)
export LIBRARY_PATH=\$(remove_duplicate \$LIBRARY_PATH)
export LD_LIBRARY_PATH=\$(remove_duplicate \$LD_LIBRARY_PATH)
export MANPATH=\$(remove_duplicate \$MANPATH)
unset -f remove_duplicate

# Utilities
if [ -f \$HOME/.dotfiles/utilities.sh ]; then
	. \$HOME/.dotfiles/utilities.sh
fi

# Path to your oh-my-zsh installation.
export ZSH="\$HOME/.oh-my-zsh"
ZSH_COMPDUMP="\$HOME/.zcompdump"
HISTFILE="\$HOME/.zsh_history"
DEFAULT_USER="$USER"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo \$RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Powerlevel9k configrations
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%K{white}%F{black} \\ue795 \\uf155 %f%k%F{white}\\ue0b0%f "
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(anaconda context root_indicator dir dir_writable vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time status time ssh)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_SHOW_CHANGESET=true
POWERLEVEL9K_CHANGESET_HASH_LENGTH=6
POWERLEVEL9K_VCS_SHORTEN_LENGTH=4
POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH=9
POWERLEVEL9K_VCS_SHORTEN_STRATEGY="truncate_middle"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

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

# Would you like to use another custom folder than \$ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    archlinux
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
    colored-man-pages
    git
    git-auto-fetch
    python
    vscode
)

ZSH_DISABLE_COMPFIX=true

source \$ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:\$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n \$SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run \$(alias).
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
EOF

backup_dotfiles .zshrc .dotfiles/.zshrc

cat >.dotfiles/.zshrc <<EOF
# Source common configrations
source \$HOME/.dotfiles/.zshrc-common

# Setup colorls
source \$(dirname \$(gem which colorls))/tab_complete.sh
alias lc='colorls --sd --gs'
alias ls='lc'
alias lsa='ls -A'
alias l='ls -la'
alias ll='ls -l'
alias la='ls -lA'
EOF

ln -sf .dotfiles/.zshrc .

backup_dotfiles .dotfiles/zsh_purepower
mkdir -p .dotfiles/zsh_purepower

cat >.dotfiles/zsh_purepower/.zshrc <<EOF
# Source common configrations
source \$HOME/.dotfiles/.zshrc-common

# Use powerlevel10k purepower theme
source \$ZSH_CUSTOM/themes/powerlevel10k/config/p10k-lean.zsh
EOF

cat >.dotfiles/zsh_purepower/zsh <<EOF
#!/usr/bin/zsh -df

export ZDOTDIR=\$HOME/.dotfiles/zsh_purepower

/usr/bin/zsh "\$@"

exit
EOF

chmod +x .dotfiles/zsh_purepower/zsh
echo_and_eval 'sudo ln -sf $HOME/.dotfiles/zsh_purepower/zsh /usr/local/bin/zsh_purepower'
if ! grep -qF '/usr/local/bin/zsh_purepower' /etc/shells; then
	echo_and_eval 'echo "/usr/local/bin/zsh_purepower" | sudo tee -a /etc/shells'
fi

backup_dotfiles .dotfiles/utilities.sh

cat >.dotfiles/utilities.sh <<EOF
#!/usr/bin/env bash

function echo_and_eval() {
	local CMD="\$*"
	printf "%s" "\$CMD" | awk \\
		'BEGIN {
			BoldGreen="\\033[1;32m";
			BoldYellow="\\033[1;33m";
			BoldWhite="\\033[1;37m";
			Reset="\\033[0m";
			printf("%s\$%s", BoldWhite, Reset);
		}
		{
			for (i = 1; i <= NF; ++i) {
				Style = BoldWhite;
				if (\$i ~ /^-/) {
					Style = BoldYellow;
				} else if (i == 1 || \$i == "sudo" || \$(i - 1) == "sudo") {
					Style = BoldGreen;
				}
				printf(" %s%s%s", Style, \$i, Reset);
			}
		}
		END {
			printf("\\n");
		}'
	eval "\$CMD"
}

function upgrade_manjaro() {
	# Upgrade Packages
	echo_and_eval 'sudo pacman -Syy'
	echo_and_eval 'sudo pacman -Syu --noconfirm'

	# Remove Unused Packages
	echo_and_eval 'sudo paccache -ruk0'

	# Clean Cache
	echo_and_eval 'sudo pacman -Scc --noconfirm'
}

function upgrade_ohmyzsh() {
	# Config
	export ZSH=\${ZSH:-\$HOME/.oh-my-zsh}
	export ZSH_CUSTOM=\${ZSH_CUSTOM:-\$ZSH/custom}

	# Upgrade oh my zsh
	echo_and_eval 'zsh \$ZSH/tools/upgrade.sh'

	# Upgrade themes
	for theme in \$(basename -a \$(/bin/ls -Ad \$ZSH_CUSTOM/themes/*/)); do
		if [ -d \$ZSH_CUSTOM/themes/\$theme/.git ]; then
			echo_and_eval "git -C \\\$ZSH_CUSTOM/themes/\$theme pull"
		fi
	done

	# Upgrade plugins
	for plugin in \$(basename -a \$(/bin/ls -Ad \$ZSH_CUSTOM/plugins/*/)); do
		if [ -d \$ZSH_CUSTOM/plugins/\$plugin/.git ]; then
			echo_and_eval "git -C \\\$ZSH_CUSTOM/plugins/\$plugin pull"
		fi
	done
}

function upgrade_vim() {
	echo_and_eval 'vim -c "PlugUpgrade | PlugUpdate | qa"'
}

function upgrade_gems() {
	echo_and_eval 'gem update --system'
	echo_and_eval 'gem update'
	echo_and_eval 'gem cleanup'
}

function upgrade_conda() {
	# Upgrade Conda
	echo_and_eval 'conda update conda --name base --yes'

	# Upgrade Conda Packages
	echo_and_eval 'conda update --all --name base --yes'
	if \$(conda list --name base | grep -q '^anaconda[^-]'); then
		echo_and_eval 'conda update anaconda --name base --yes'
	fi

	# Upgrade Conda Packages in Each Environment
	for env in \$(basename -a \$(/bin/ls -Ad \$(conda info --base)/envs/*/)); do
		echo_and_eval "conda update --all --name \$env --yes"
		if \$(conda list --name \$env | grep -q '^anaconda[^-]'); then
			echo_and_eval "conda update anaconda --name \$env --yes"
		fi
	done

	# Clean Conda Cache
	echo_and_eval 'conda clean --all --yes'
}

function send_to_mac() {
	local SOURCE="\$1"
	local TARGET=\${2:-'~/Downloads/'}
	local USER_NAME="PanXuehai"
	local TARGET_HOST="PanXuehai-MacBook-Pro.local"
	if [ -n "\$SSH_CLIENT" ] && [ -n "\$SSH_CONNECTION" ]; then
		TARGET_HOST=\$(echo \$SSH_CLIENT | awk '{ print \$1 }')
	fi
	echo_and_eval "rsync -avhh -P \\"\$SOURCE\\" \$USER_NAME@\$TARGET_HOST:\\"\$TARGET\\""
}

function recieve_from_mac() {
	local SOURCE="\$1"
	local TARGET=\${2:-'\$HOME/Downloads/'}
	local USER_NAME="PanXuehai"
	local SOURCE_HOST="PanXuehai-MacBook-Pro.local"
	if [ -n "\$SSH_CLIENT" ] && [ -n "\$SSH_CONNECTION" ]; then
		SOURCE_HOST=\$(echo \$SSH_CLIENT | awk '{ print \$1 }')
	fi
	echo_and_eval "rsync -avhh -P \$USER_NAME@\$SOURCE_HOST:\\"\$SOURCE\\" \\"\$TARGET\\""
}

function auto_reannounce_trackers() {
	local TIMES=\${1:-60}
	local INTERVAL=\${2:-60}
	local TORRENT="active"
	local CMD=""
	local RESULT=""
	local INFO=""

	echo -ne "\\033[?25l"

	for ((t = 0; i <= TIMES; ++i)); do
		if [ \$((t % 5)) -ne 0 ]; then
			TORRENT="active"
		else
			TORRENT="all"
		fi
		CMD="transmission-remote --torrent \$TORRENT --reannounce"
		eval \$CMD 1>/dev/null
		for ((r = INTERVAL - 1; r >= 0; --r)); do
			echo -ne "\$CMD (\$t/\$TIMES, next reannounce in \${r}s)\\033[K\\r"
			sleep 1
		done
	done

	echo -ne "\\033[K\\033[?25h"
}
EOF

backup_dotfiles .bashrc .dotfiles/.bashrc

if ! grep -qF 'export PS1=' .bashrc; then
	cat >>.bashrc <<EOF

# User specific environment and startup programs
export TERM="xterm-256color"
export PS1='[\\[\\e[1;33m\\]\\u\\[\\e[0m\\]@\\[\\e[1;32m\\]\\h\\[\\e[0m\\]:\\[\\e[1;35m\\]\\W\\[\\e[0m\\]]\\\$ '

# locale
export LANG="en_US.UTF-8"
EOF
fi

mv -f .bashrc .dotfiles/
ln -sf .dotfiles/.bashrc .

backup_dotfiles .profile .dotfiles/.profile

cat >.dotfiles/.profile <<EOF
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "\$BASH_VERSION" ]; then
	# include .bashrc if it exists
	if [ -f "\$HOME/.bashrc" ]; then
		. "\$HOME/.bashrc"
	fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "\$HOME/.local/bin" ]; then
	export PATH="\$HOME/.local/bin:\$PATH"
fi

# set C_INCLUDE_PATH and CPLUS_INCLUDE_PATH so it includes user's private include if it exists
if [ -d "\$HOME/.local/include" ]; then
	export C_INCLUDE_PATH="\$HOME/.local/include:\$C_INCLUDE_PATH"
	export CPLUS_INCLUDE_PATH="\$HOME/.local/include:\$CPLUS_INCLUDE_PATH"
	export INCLUDE_PATH="\$HOME/.local/include:\$INCLUDE_PATH"
fi

# set LIBRARY_PATH and LD_LIBRARY_PATH so it includes user's private lib if it exists
if [ -d "\$HOME/.local/lib" ]; then
	export LIBRARY_PATH="\$HOME/.local/lib:\$LIBRARY_PATH"
	export LD_LIBRARY_PATH="\$HOME/.local/lib:\$LD_LIBRARY_PATH"
fi

# set MANPATH so it includes user's private man if it exists
if [ -d "\$HOME/.local/man" ]; then
	export MANPATH="\$HOME/.local/man:\$MANPATH"
fi

# Compilers
export CC="/usr/bin/gcc"
export CXX="/usr/bin/g++"
export FC="/usr/bin/gfortran"
export OMPI_CC="\$CC"
export OMPI_CXX="\$CXX"
export OMPI_FC="\$FC"

# Anaconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="\$('\$HOME/Miniconda3/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
if [ \$? -eq 0 ]; then
	eval "\$__conda_setup"
else
	if [ -f "\$HOME/Miniconda3/etc/profile.d/conda.sh" ]; then
		. "\$HOME/Miniconda3/etc/profile.d/conda.sh"
	else
		export PATH="\$HOME/Miniconda3/bin:\$PATH"
	fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Ruby
export PATH="\$(ruby -r rubygems -e 'puts Gem.dir')/bin:\$PATH"
export PATH="\$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:\$PATH"

# Remove duplicate entries
function remove_duplicate() {
	for item in "\$@"; do
		echo \$(printf "%s" "\$item" | awk -v RS=':' 'BEGIN { idx = 0; delete flag; } { if (!(flag[\$0]++)) { printf("%s%s", (!idx++ ? "" : ":"), \$0); } }')
	done
}
export PATH=\$(remove_duplicate \$PATH)
export C_INCLUDE_PATH=\$(remove_duplicate \$C_INCLUDE_PATH)
export CPLUS_INCLUDE_PATH=\$(remove_duplicate \$CPLUS_INCLUDE_PATH)
export INCLUDE_PATH=\$(remove_duplicate \$INCLUDE_PATH)
export LIBRARY_PATH=\$(remove_duplicate \$LIBRARY_PATH)
export LD_LIBRARY_PATH=\$(remove_duplicate \$LD_LIBRARY_PATH)
export MANPATH=\$(remove_duplicate \$MANPATH)
unset -f remove_duplicate
EOF

ln -sf .dotfiles/.profile .

backup_dotfiles .vimrc .dotfiles/.vimrc

cat >.dotfiles/.vimrc <<EOF
set nocompatible
set backspace=indent,eol,start
syntax on
set showmode
set fileformats=unix,dos
set encoding=utf-8
filetype plugin indent on
set completeopt=menu,preview,longest
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set list
set listchars=tab:▸\\ ,trail:·
set number
set ruler
set colorcolumn=80,100,120,140
set cursorline
set foldenable
set foldmethod=indent
set foldlevel=3
set scrolloff=3
set sidescroll=5
set wrap
set showmatch
set hlsearch
set incsearch
" set spell spelllang=en_us
set autochdir
set visualbell
set autoread
set showcmd
set wildmenu
set wildmode=longest:list,full
set background=dark
set t_Co=256
set guifont=DejaVuSansMono\\ Nerd\\ Font\\ Mono\\ 10
colorscheme monokai


autocmd GUIEnter * set lines=50 columns=160

autocmd BufWritePre,FileWritePre * let pos=getpos('.') |
                                 \\ %s/\\r\\+\$//ge |
                                 \\ %s/\\s\\+\$//ge |
                                 \\ call setpos('.', pos) |
                                 \\ unlet pos

let g:NERDChristmasTree=1
let g:NERDTreeMouseMode=2
let g:NERDTreeShowBookmarks=1
let g:NERDTreeShowFiles=1
let g:NERDTreeShowHidden=1
let g:NERDTreeShowLineNumbers=0
let g:NERDTreeWinPos='left'
let g:NERDTreeWinSize=31
autocmd VimEnter * if str2nr(system("ls -l \$PWD | wc -l")) <= 1000 |
                 \\     let width = winwidth('%') |
                 \\     let numberwidth = ((&number || &relativenumber)? max([&numberwidth, strlen(line('\$')) + 1]) : 0) |
                 \\     let signwidth = ((&signcolumn == 'yes' || &signcolumn == 'auto')? 2 : 0) |
                 \\     let foldwidth = &foldcolumn |
                 \\     let bufwidth = width - numberwidth - foldwidth - signwidth |
                 \\     if bufwidth > 80 + NERDTreeWinSize |
                 \\         NERDTree |
                 \\         wincmd p |
                 \\     endif |
                 \\     unlet width numberwidth signwidth foldwidth bufwidth |
                 \\ endif
autocmd BufEnter * if (winnr('\$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree()) |
                 \\ q |
                 \\ endif


call plug#begin('~/.vim/plugged')
    Plug 'scrooloose/nerdtree'
    Plug 'scrooloose/nerdcommenter'
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'ryanoasis/vim-devicons'
    Plug 'yggdroot/indentline'
    Plug 'jiangmiao/auto-pairs'
    Plug 'airblade/vim-gitgutter'
    Plug 'tpope/vim-fugitive'
call plug#end()
EOF

ln -sf .dotfiles/.vimrc .

echo_and_eval 'curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

mkdir -p .vim/colors

cat >.vim/colors/monokai.vim <<EOF
" Vim color file
" Converted from Textmate theme Monokai using Coloration v0.3.2 (http://github.com/sickill/coloration)

set background=dark
highlight clear

if exists("syntax_on")
  syntax reset
endif

set t_Co=256
let g:colors_name = "monokai"

hi Cursor ctermfg=235 ctermbg=231 cterm=NONE guifg=#272822 guibg=#f8f8f0 gui=NONE
hi Visual ctermfg=NONE ctermbg=59 cterm=NONE guifg=NONE guibg=#49483e gui=NONE
hi CursorLine ctermfg=NONE ctermbg=237 cterm=NONE guifg=NONE guibg=#3c3d37 gui=NONE
hi CursorColumn ctermfg=NONE ctermbg=237 cterm=NONE guifg=NONE guibg=#3c3d37 gui=NONE
hi ColorColumn ctermfg=NONE ctermbg=237 cterm=NONE guifg=NONE guibg=#3c3d37 gui=NONE
hi LineNr ctermfg=102 ctermbg=237 cterm=NONE guifg=#90908a guibg=#3c3d37 gui=NONE
hi VertSplit ctermfg=241 ctermbg=241 cterm=NONE guifg=#64645e guibg=#64645e gui=NONE
hi MatchParen ctermfg=197 ctermbg=NONE cterm=underline guifg=#f92672 guibg=NONE gui=underline
hi StatusLine ctermfg=231 ctermbg=241 cterm=bold guifg=#f8f8f2 guibg=#64645e gui=bold
hi StatusLineNC ctermfg=231 ctermbg=241 cterm=NONE guifg=#f8f8f2 guibg=#64645e gui=NONE
hi Pmenu ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi PmenuSel ctermfg=NONE ctermbg=59 cterm=NONE guifg=NONE guibg=#49483e gui=NONE
hi IncSearch term=reverse cterm=reverse ctermfg=193 ctermbg=16 gui=reverse guifg=#C4BE89 guibg=#000000
hi Search term=reverse cterm=NONE ctermfg=231 ctermbg=24 gui=NONE guifg=#f8f8f2 guibg=#204a87
hi Directory ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi Folded ctermfg=242 ctermbg=235 cterm=NONE guifg=#75715e guibg=#272822 gui=NONE
hi SignColumn ctermfg=NONE ctermbg=237 cterm=NONE guifg=NONE guibg=#3c3d37 gui=NONE
hi Normal ctermfg=231 ctermbg=235 cterm=NONE guifg=#f8f8f2 guibg=#272822 gui=NONE
hi Boolean ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi Character ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi Comment ctermfg=242 ctermbg=NONE cterm=NONE guifg=#75715e guibg=NONE gui=NONE
hi Conditional ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi Constant ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi Define ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi DiffAdd ctermfg=231 ctermbg=64 cterm=bold guifg=#f8f8f2 guibg=#46830c gui=bold
hi DiffDelete ctermfg=88 ctermbg=NONE cterm=NONE guifg=#8b0807 guibg=NONE gui=NONE
hi DiffChange ctermfg=NONE ctermbg=NONE cterm=NONE guifg=#f8f8f2 guibg=#243955 gui=NONE
hi DiffText ctermfg=231 ctermbg=24 cterm=bold guifg=#f8f8f2 guibg=#204a87 gui=bold
hi ErrorMsg ctermfg=231 ctermbg=197 cterm=NONE guifg=#f8f8f0 guibg=#f92672 gui=NONE
hi WarningMsg ctermfg=231 ctermbg=197 cterm=NONE guifg=#f8f8f0 guibg=#f92672 gui=NONE
hi Float ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi Function ctermfg=148 ctermbg=NONE cterm=NONE guifg=#a6e22e guibg=NONE gui=NONE
hi Identifier ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=italic
hi Keyword ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi Label ctermfg=186 ctermbg=NONE cterm=NONE guifg=#e6db74 guibg=NONE gui=NONE
hi NonText ctermfg=59 ctermbg=236 cterm=NONE guifg=#49483e guibg=#31322c gui=NONE
hi Number ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi Operator ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi PreProc ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi Special ctermfg=231 ctermbg=NONE cterm=NONE guifg=#f8f8f2 guibg=NONE gui=NONE
hi SpecialComment ctermfg=242 ctermbg=NONE cterm=NONE guifg=#75715e guibg=NONE gui=NONE
hi SpecialKey ctermfg=59 ctermbg=237 cterm=NONE guifg=#49483e guibg=#3c3d37 gui=NONE
hi Statement ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi StorageClass ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=italic
hi String ctermfg=186 ctermbg=NONE cterm=NONE guifg=#e6db74 guibg=NONE gui=NONE
hi Tag ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi Title ctermfg=231 ctermbg=NONE cterm=bold guifg=#f8f8f2 guibg=NONE gui=bold
hi Todo ctermfg=95 ctermbg=NONE cterm=inverse,bold guifg=#75715e guibg=NONE gui=inverse,bold
hi Type ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi Underlined ctermfg=NONE ctermbg=NONE cterm=underline guifg=NONE guibg=NONE gui=underline
hi rubyClass ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi rubyFunction ctermfg=148 ctermbg=NONE cterm=NONE guifg=#a6e22e guibg=NONE gui=NONE
hi rubyInterpolationDelimiter ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi rubySymbol ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi rubyConstant ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=italic
hi rubyStringDelimiter ctermfg=186 ctermbg=NONE cterm=NONE guifg=#e6db74 guibg=NONE gui=NONE
hi rubyBlockParameter ctermfg=208 ctermbg=NONE cterm=NONE guifg=#fd971f guibg=NONE gui=italic
hi rubyInstanceVariable ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi rubyInclude ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi rubyGlobalVariable ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi rubyRegexp ctermfg=186 ctermbg=NONE cterm=NONE guifg=#e6db74 guibg=NONE gui=NONE
hi rubyRegexpDelimiter ctermfg=186 ctermbg=NONE cterm=NONE guifg=#e6db74 guibg=NONE gui=NONE
hi rubyEscape ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi rubyControl ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi rubyClassVariable ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi rubyOperator ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi rubyException ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi rubyPseudoVariable ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi rubyRailsUserClass ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=italic
hi rubyRailsARAssociationMethod ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=NONE
hi rubyRailsARMethod ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=NONE
hi rubyRailsRenderMethod ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=NONE
hi rubyRailsMethod ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=NONE
hi erubyDelimiter ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi erubyComment ctermfg=95 ctermbg=NONE cterm=NONE guifg=#75715e guibg=NONE gui=NONE
hi erubyRailsMethod ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=NONE
hi htmlTag ctermfg=148 ctermbg=NONE cterm=NONE guifg=#a6e22e guibg=NONE gui=NONE
hi htmlEndTag ctermfg=148 ctermbg=NONE cterm=NONE guifg=#a6e22e guibg=NONE gui=NONE
hi htmlTagName ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi htmlArg ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi htmlSpecialChar ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi javaScriptFunction ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=italic
hi javaScriptRailsFunction ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=NONE
hi javaScriptBraces ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi yamlKey ctermfg=197 ctermbg=NONE cterm=NONE guifg=#f92672 guibg=NONE gui=NONE
hi yamlAnchor ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi yamlAlias ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
hi yamlDocumentHeader ctermfg=186 ctermbg=NONE cterm=NONE guifg=#e6db74 guibg=NONE gui=NONE
hi cssURL ctermfg=208 ctermbg=NONE cterm=NONE guifg=#fd971f guibg=NONE gui=italic
hi cssFunctionName ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=NONE
hi cssColor ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi cssPseudoClassId ctermfg=148 ctermbg=NONE cterm=NONE guifg=#a6e22e guibg=NONE gui=NONE
hi cssClassName ctermfg=148 ctermbg=NONE cterm=NONE guifg=#a6e22e guibg=NONE gui=NONE
hi cssValueLength ctermfg=141 ctermbg=NONE cterm=NONE guifg=#ae81ff guibg=NONE gui=NONE
hi cssCommonAttr ctermfg=81 ctermbg=NONE cterm=NONE guifg=#66d9ef guibg=NONE gui=NONE
hi cssBraces ctermfg=NONE ctermbg=NONE cterm=NONE guifg=NONE guibg=NONE gui=NONE
EOF

echo_and_eval 'vim -c "PlugUpgrade | PlugInstall | PlugUpdate | qa"'

backup_dotfiles .tmux.conf .dotfiles/.tmux.conf \
	.tmux.conf.local .dotfiles/.tmux.conf.local \
	.tmux.conf.user .dotfiles/.tmux.conf.user

cat >.dotfiles/.tmux.conf.user <<EOF
# Set default terminal
set-option -gs default-terminal "tmux-256color"
set-option -gsa terminal-overrides ",xterm-termite:Tc"
set-option -gs default-shell /usr/bin/zsh
# set-option -gs default-command "reattach-to-user-namespace -l zsh"

# Automatically set window title
set-option -gs automatic-rename on
set-option -gs set-titles on
set-option -gs base-index 1
set-option -gs pane-base-index 1

# Miscellaneous
set-option -gs -q utf8 on
set-option -gs status-keys vi
set-option -gs mode-keys vi
set-option -gs history-limit 10000

set-option -gs mouse on
set-option -gs monitor-activity on
set-option -gs visual-activity on
set-option -gs visual-bell off
set-option -gs repeat-time 1000

# Add second prefix key
set-option -gs prefix2 C-a
bind-key C-a send-prefix -2

# Split window
bind-key | split-window -h
bind-key - split-window -v
bind-key H split-window -h
bind-key V split-window -v

# Vim style pane selection
bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R

# Use Alt-vim keys without prefix key to switch panes
bind-key -n M-h select-pane -L
bind-key -n M-j select-pane -D
bind-key -n M-k select-pane -U
bind-key -n M-l select-pane -R

# Use Alt-vim keys to resize panes
bind-key -r M-j resize-pane -D 5
bind-key -r M-k resize-pane -U 5
bind-key -r M-h resize-pane -L 5
bind-key -r M-l resize-pane -R 5

# Use Ctrl-vim keys to resize panes
bind-key -r C-j resize-pane -D
bind-key -r C-k resize-pane -U
bind-key -r C-h resize-pane -L
bind-key -r C-l resize-pane -R

# Use Alt-arrow keys without prefix key to switch panes
bind-key -n M-Left select-pane -L
bind-key -n M-Right select-pane -R
bind-key -n M-Up select-pane -U
bind-key -n M-Down select-pane -D

# Use Alt-arrow keys to resize panes
bind-key -r M-Left resize-pane -L 5
bind-key -r M-Right resize-pane -R 5
bind-key -r M-Up resize-pane -U 5
bind-key -r M-Down resize-pane -D 5

# Use Ctrl-arrow keys to resize panes
bind-key -r C-Left resize-pane -L
bind-key -r C-Right resize-pane -R
bind-key -r C-Up resize-pane -U
bind-key -r C-Down resize-pane -D

# Use Shift-arrow keys without prefix key to switch windows
bind-key -n S-Left previous-window
bind-key -n S-Right next-window

# Reload tmux config
bind-key r source-file ~/.tmux.conf \\; display-message "tmux.conf reloaded"

# Theme
# set-option -gs window-style fg=white
# set-option -gs window-active-style fg=brightwhite
# set-option -gs pane-border-status top
# set-option -gs pane-border-style fg=white,default
# set-option -gs pane-active-border-style fg=brightgreen,bold
# set-option -gs -q status-utf8 on
# set-option -gs status-position bottom
# set-option -gs status-interval 1
# set-option -gs status-bg blue
# set-option -gs status-fg black
# set-option -gs status-attr bold
# set-option -gs window-status-fg colour208
# set-option -gs window-status-current-fg colour129
# set-option -gs status-left-length 30
# set-option -gs status-right-length 90
# set-option -gs status-left '#[none][#{session_name}]#[default] '
# set-option -gs status-right ' #[fg=colour120][#{?#{==:#{=-60:pane_title},#{pane_title}},#{pane_title},…#{=-59:pane_title}}]#[default] #[none]%a %b-%d %H:%M:%S#[default] '
EOF

backup_dotfiles .dotfiles/.tmux
rm -rf .dotfiles/.tmux
git clone https://github.com/gpakosz/.tmux.git .dotfiles/.tmux

cp -f .dotfiles/.tmux/.tmux.conf.local .dotfiles/
ln -sf .dotfiles/.tmux/.tmux.conf .
ln -sf .dotfiles/.tmux.conf.local .

sed -i -e 's/tmux_conf_copy_to_os_clipboard=false/tmux_conf_copy_to_os_clipboard=true/g' .dotfiles/.tmux.conf.local
sed -i -e 's/#set -g history-limit 10000/set -g history-limit 10000/g' .dotfiles/.tmux.conf.local
sed -i -e 's/#set -g mouse on/set -g mouse on/g' .dotfiles/.tmux.conf.local
cat >>.dotfiles/.tmux.conf.local <<EOF

%if '[ -f ~/.dotfiles/.tmux.conf.user ]'
    source-file ~/.dotfiles/.tmux.conf.user
%endif
EOF

backup_dotfiles .gitconfig .dotfiles/.gitconfig

cat >.dotfiles/.gitconfig <<EOF
[user]
	name = XuehaiPan
	email = XuehaiPan@pku.edu.cn

[core]
	excludesfile = ~/.gitignore_global
	editor = vim

[diff]
	tool = vimdiff
	algorithm = minimal

[difftool]
	prompt = false

[merge]
	tool = vimdiff

[mergetool]
	prompt = false

[fetch]
	prune = true
	parallel = 0

[submodule]
	recurse = true
	fetchJobs = 0

[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true

[color]
	ui = true
EOF

ln -sf .dotfiles/.gitconfig .

backup_dotfiles .gitignore_global .dotfiles/.gitignore_global

cat >.dotfiles/.gitignore_global <<EOF
##### macOS.gitignore #####
# General
.DS_Store
.AppleDouble
.LSOverride

# Icon must end with two \\r
Icon


# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk



##### Linux.gitignore #####
*~

# temporary files which can be created if a process still has a handle open of a deleted file
.fuse_hidden*

# KDE directory preferences
.directory

# Linux trash folder which might appear on any partition or disk
.Trash-*

# .nfs files are created when an open file is removed but is still being accessed
.nfs*



##### Windows.gitignore #####
# Windows thumbnail cache files
Thumbs.db
ehthumbs.db
ehthumbs_vista.db

# Dump file
*.stackdump

# Folder config file
[Dd]esktop.ini

# Recycle Bin used on file shares
\$RECYCLE.BIN/

# Windows Installer files
*.cab
*.msi
*.msix
*.msm
*.msp

# Windows shortcuts
*.lnk



##### Archives.gitignore #####
# It's better to unpack these files and commit the raw source because
# git has its own built in compression methods.
*.7z
*.jar
*.rar
*.zip
*.gz
*.tgz
*.bzip
*.bz2
*.xz
*.lzma
*.cab

# Packing-only formats
*.iso
*.tar

# Package management formats
*.dmg
*.xpi
*.gem
*.egg
*.deb
*.rpm
*.msi
*.msm
*.msp



##### Xcode.gitignore #####
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore

## Build generated
build/
DerivedData/

## Various settings
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/

## Other
*.moved-aside
*.xccheckout
*.xcscmblueprint

## Obj-C/Swift specific
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

# Swift Package Manager
#
# Add this line if you want to avoid checking in source code from Swift Package Manager dependencies.
# Packages/
# Package.pins
# Package.resolved
.build/

# CocoaPods
#
# We recommend against adding the Pods directory to your .gitignore. However
# you should judge for yourself, the pros and cons are mentioned at:
# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control
#
# Pods/
#
# Add this line if you want to avoid checking in source code from the Xcode workspace
# *.xcworkspace

# Carthage
#
# Add this line if you want to avoid checking in source code from Carthage dependencies.
# Carthage/Checkouts

Carthage/Build

# fastlane
#
# It is recommended to not store the screenshots in the git repo. Instead, use fastlane to re-generate the
# screenshots whenever they are needed.
# For more information about the recommended setup visit:
# https://docs.fastlane.tools/best-practices/source-control/#source-control

fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
#
# After new code Injection tools there's a generated folder /iOSInjectionProject
# https://github.com/johnno1962/injectionforxcode

iOSInjectionProject/



##### JetBrains.gitignore #####
# Covers JetBrains IDEs: IntelliJ, RubyMine, PhpStorm, AppCode, PyCharm, CLion, Android Studio and WebStorm
# Reference: https://intellij-support.jetbrains.com/hc/en-us/articles/206544839

# User settings
.idea/*

# User-specific stuff
.idea/**/workspace.xml
.idea/**/tasks.xml
.idea/**/usage.statistics.xml
.idea/**/dictionaries
.idea/**/shelf

# Generated files
.idea/**/contentModel.xml

# Sensitive or high-churn files
.idea/**/dataSources/
.idea/**/dataSources.ids
.idea/**/dataSources.local.xml
.idea/**/sqlDataSources.xml
.idea/**/dynamic.xml
.idea/**/uiDesigner.xml
.idea/**/dbnavigator.xml

# Gradle
.idea/**/gradle.xml
.idea/**/libraries

# Gradle and Maven with auto-import
# When using Gradle or Maven with auto-import, you should exclude module files,
# since they will be recreated, and may cause churn.  Uncomment if using
# auto-import.
# .idea/modules.xml
# .idea/*.iml
# .idea/modules

# CMake
cmake-build-*/

# Mongo Explorer plugin
.idea/**/mongoSettings.xml

# File-based project format
*.iws

# IntelliJ
out/

# mpeltonen/sbt-idea plugin
.idea_modules/

# JIRA plugin
atlassian-ide-plugin.xml

# Cursive Clojure plugin
.idea/replstate.xml

# Crashlytics plugin (for Android Studio and IntelliJ)
com_crashlytics_export_strings.xml
crashlytics.properties
crashlytics-build.properties
fabric.properties

# Editor-based Rest Client
.idea/httpRequests

# Android studio 3.1+ serialized cache file
.idea/caches/build_file_checksums.ser



##### VisualStudioCode.gitignore #####
.vscode/*
# !.vscode/settings.json
# !.vscode/tasks.json
# !.vscode/launch.json
# !.vscode/extensions.json
EOF

ln -sf .dotfiles/.gitignore_global .

backup_dotfiles .condarc .dotfiles/.condarc

cat >.dotfiles/.condarc <<EOF
auto_update_conda: true

channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/pro/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
  # - defaults
  # - default
  # - conda-forge
  # - r
  # - pytorch

ssl_verify: true

show_channel_urls: false

auto_activate_base: false

create_default_packages:
  # - anaconda
  - pip
  - jupyter
  - ipython
  - notebook
  - jupyterlab
  - ipdb
  - cython
  - numpy
  - numba
  - matplotlib
  - pandas
  - seaborn
  - pygraphviz
  - yapf
  - autopep8
  - pycodestyle
  - pylint
EOF

ln -sf .dotfiles/.condarc .

echo_and_eval 'wget -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh'
CONDA_ARGS="-b -p $HOME/Miniconda3"
if [[ -d "$HOME/Miniconda3" ]]; then
	CONDA_ARGS="$CONDA_ARGS -u"
fi
echo_and_eval "bash Miniconda3-latest-Linux-x86_64.sh $CONDA_ARGS"
echo_and_eval 'rm -f Miniconda3-latest-Linux-x86_64.sh'

source .zshrc 2>/dev/null
echo_and_eval 'conda update conda --yes'
echo_and_eval 'conda install pip jupyter ipython notebook jupyterlab ipdb \
							 cython numpy numba matplotlib pandas seaborn pygraphviz \
							 yapf autopep8 pycodestyle pylint --yes'
echo_and_eval 'conda update --all --yes'
echo_and_eval 'conda clean --all --yes'
rm -r .cph_tmp* 2>/dev/null
rm -r Miniconda3/.cph_tmp* 2>/dev/null

cat >upgrade_packages.sh <<EOF
#!/usr/bin/env bash

function echo_and_eval() {
	local CMD="\$*"
	printf "%s" "\$CMD" | awk \\
		'BEGIN {
			BoldGreen="\\033[1;32m";
			BoldYellow="\\033[1;33m";
			BoldWhite="\\033[1;37m";
			Reset="\\033[0m";
			printf("%s\$%s", BoldWhite, Reset);
		}
		{
			for (i = 1; i <= NF; ++i) {
				Style = BoldWhite;
				if (\$i ~ /^-/) {
					Style = BoldYellow;
				} else if (i == 1 || \$i == "sudo" || \$(i - 1) == "sudo") {
					Style = BoldGreen;
				}
				printf(" %s%s%s", Style, \$i, Reset);
			}
		}
		END {
			printf("\\n");
		}'
	eval "\$CMD"
}

function upgrade_manjaro() {
	# Upgrade Packages
	echo_and_eval 'sudo pacman -Syy'
	echo_and_eval 'sudo pacman -Syu --noconfirm'

	# Remove Unused Packages
	echo_and_eval 'sudo paccache -ruk0'

	# Clean Cache
	echo_and_eval 'sudo pacman -Scc --noconfirm'
}

function upgrade_ohmyzsh() {
	# Config
	export ZSH=\${ZSH:-\$HOME/.oh-my-zsh}
	export ZSH_CUSTOM=\${ZSH_CUSTOM:-\$ZSH/custom}

	# Upgrade oh my zsh
	echo_and_eval 'zsh \$ZSH/tools/upgrade.sh'

	# Upgrade themes
	for theme in \$(basename -a \$(/bin/ls -Ad \$ZSH_CUSTOM/themes/*/)); do
		if [ -d \$ZSH_CUSTOM/themes/\$theme/.git ]; then
			echo_and_eval "git -C \\\$ZSH_CUSTOM/themes/\$theme pull"
		fi
	done

	# Upgrade plugins
	for plugin in \$(basename -a \$(/bin/ls -Ad \$ZSH_CUSTOM/plugins/*/)); do
		if [ -d \$ZSH_CUSTOM/plugins/\$plugin/.git ]; then
			echo_and_eval "git -C \\\$ZSH_CUSTOM/plugins/\$plugin pull"
		fi
	done
}

function upgrade_vim() {
	echo_and_eval 'vim -c "PlugUpgrade | PlugUpdate | qa"'
}

function upgrade_gems() {
	echo_and_eval 'gem update --system'
	echo_and_eval 'gem update'
	echo_and_eval 'gem cleanup'
}

function upgrade_conda() {
	# Upgrade Conda
	echo_and_eval 'conda update conda --name base --yes'

	# Upgrade Conda Packages
	echo_and_eval 'conda update --all --name base --yes'
	if \$(conda list --name base | grep -q '^anaconda[^-]'); then
		echo_and_eval 'conda update anaconda --name base --yes'
	fi

	# Upgrade Conda Packages in Each Environment
	for env in \$(basename -a \$(/bin/ls -Ad \$(conda info --base)/envs/*/)); do
		echo_and_eval "conda update --all --name \$env --yes"
		if \$(conda list --name \$env | grep -q '^anaconda[^-]'); then
			echo_and_eval "conda update anaconda --name \$env --yes"
		fi
	done

	# Clean Conda Cache
	echo_and_eval 'conda clean --all --yes'
}

upgrade_manjaro
upgrade_ohmyzsh
upgrade_vim
upgrade_gems
# upgrade_conda

if [ -n "\$ZSH_VERSION" ]; then
	if [ -f \$HOME/.zshrc ]; then
		source \$HOME/.zshrc
	fi
elif [ -n "\$BASH_VERSION" ]; then
	if [ -f \$HOME/.profile ]; then
		source \$HOME/.profile
	fi
fi
EOF

chmod +x upgrade_packages.sh

FONT_DIR=".local/share/fonts"
if $IS_WSL; then
	FONT_DIR="/mnt/c/Windows/Fonts"
else
	mkdir -p "$FONT_DIR"
fi
echo_and_eval 'wget -O DejaVuSansMono.zip -c https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/DejaVuSansMono.zip'
echo_and_eval 'wget -O Menlo.zip -c https://raw.githubusercontent.com/XuehaiPan/OS-Setup/master/Menlo.zip'
echo_and_eval "wget -O $FONT_DIR/Cascadia.ttf -c https://github.com/microsoft/cascadia-code/releases/download/v1911.21/Cascadia.ttf"
echo_and_eval "wget -O $FONT_DIR/CascadiaPL.ttf -c https://github.com/microsoft/cascadia-code/releases/download/v1911.21/CascadiaPL.ttf"
echo_and_eval "wget -O $FONT_DIR/CascadiaMono.ttf -c https://github.com/microsoft/cascadia-code/releases/download/v1911.21/CascadiaMono.ttf"
echo_and_eval "wget -O $FONT_DIR/CascadiaMonoPL.ttf -c https://github.com/microsoft/cascadia-code/releases/download/v1911.21/CascadiaMonoPL.ttf"
echo_and_eval "unzip -o DejaVuSansMono.zip -d $FONT_DIR/"
echo_and_eval "unzip -o Menlo.zip -d $FONT_DIR/"
echo_and_eval 'rm -f DejaVuSansMono.zip Menlo.zip'
if ! $IS_WSL; then
	echo_and_eval 'sudo fc-cache --force'
fi
