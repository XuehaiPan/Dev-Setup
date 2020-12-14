#!/usr/bin/env bash

# Options
export SET_MIRRORS="${SET_MIRRORS:-true}"

# Set USER
export USER="${USER:-"$(whoami)"}"

# Set configuration backup directory
DATETIME="$(date +"%Y-%m-%d-%T")"
BACKUP_DIR="$HOME/.dotfiles/backups/$DATETIME"
mkdir -p "$BACKUP_DIR/.dotfiles"
ln -sfn "$DATETIME" "$HOME/.dotfiles/backups/latest"

# Set temporary directory
TMP_DIR="$(mktemp -d -t os-setup.XXXXXX)"

# Check if has sudo privileges
IS_SUDOER=false
if groups | grep -qE '(wheel|root)'; then
	IS_SUDOER=true
fi

# Check if in WSL
IN_WSL=false
if [[ -n "$WSL_DISTRO_NAME" ]] || (uname -r | grep -qF 'Microsoft'); then
	IN_WSL=true
fi

# Set default Conda installation directory
CONDA_DIR="Miniconda3"
if [[ -d "$HOME/miniconda3" && ! -d "$HOME/Miniconda3" ]]; then
	CONDA_DIR="miniconda3"
elif [[ -d "$HOME/Anaconda3" ]]; then
	CONDA_DIR="Anaconda3"
elif [[ -d "$HOME/anaconda3" ]]; then
	CONDA_DIR="anaconda3"
fi

# Common functions
function echo_and_eval() {
	printf "%s" "$@" | awk -f <(
		cat - <<-EOD
			BEGIN {
				BOLD = "\\033[1m"
				UNDERLINE = "\\033[4m";
				RED = "\\033[31m";
				GREEN = "\\033[32m";
				YELLOW = "\\033[33m";
				WHITE = "\\033[37m";
				RESET = "\\033[0m";
				idx = 0;
				in_string = 0;
				double_quoted = 1;
				printf("%s\$", BOLD WHITE);
			}
			{
				for (i = 1; i <= NF; ++i) {
					style = WHITE;
					style_post = WHITE;
					if (!in_string) {
						if (\$i ~ /^-/)
							style = YELLOW;
						else if (\$i == "sudo" && idx == 0) {
							style = UNDERLINE GREEN;
							style_post = RESET BOLD WHITE;
						}
						else if (\$i ~ /^[12&]?>>?/)
							style = RED;
						else {
							++idx;
							if (\$i ~ /^"/) {
								in_string = 1;
								double_quoted = 1;
							}
							else if (\$i ~ /^'/) {
								in_string = 1;
								double_quoted = 0;
							}
							if (idx == 1)
								style = GREEN;
						}
					}
					if (in_string) {
						if ((double_quoted && \$i ~ /";?\$/ && \$i !~ /\\\\";?\$/) || (!double_quoted && \$i ~ /';?\$/))
							in_string = 0;
					}
					if (\$i ~ /;\$/ || \$i == "|" || \$i == "||" || \$i == "&&") {
						if (!in_string) {
							idx = 0;
							if (\$i !~ /;\$/)
								style = RED;
						}
					}
					if (\$i ~ /;\$/)
						printf(" %s%s%s;%s", style, substr(\$i, 1, length(\$i) - 1), (in_string ? WHITE : RED), style_post);
					else
						printf(" %s%s%s", style, \$i, style_post);
					if (\$i == "\\\\")
						printf("\\n\\t");
				}
			}
			END {
				printf("%s\\n", RESET);
			}
		EOD
	) >&2
	eval "$@"
}

function backup_dotfiles() {
	local file original_file
	for file in "$@"; do
		if [[ -f "$file" || -d "$file" ]]; then
			if [[ -L "$file" ]]; then
				original_file="$(realpath "$file")"
				rm -f "$file"
				cp -rf "$original_file" "$file"
			fi
			cp -rf "$file" "$BACKUP_DIR/$file"
		fi
	done
}

function wget() {
	command wget --no-verbose --show-progress --progress=bar:force:noscroll "$@"
}

function get_latest_version() {
	local REPO="$1"
	local VERSION=""
	local i
	for ((i = 0; i < 5; ++i)); do
		VERSION="$(
			curl --silent --connect-timeout 10 "https://api.github.com/repos/$REPO/releases/latest" |
				grep '"tag_name":' |
				sed -E 's/^.*:\s*"([^"]+)",?$/\1/'
		)"
		if [[ -n "$VERSION" ]]; then
			break
		fi
	done
	echo "$VERSION"
}

if $IS_SUDOER; then
	# Setup Pacman configurations
	if $SET_MIRRORS; then
		for repo in "arch4edu" "archlinuxcn"; do
			if ! grep -qF "[$repo]" /etc/pacman.conf; then
				echo_and_eval "printf \"\\n%s\\n%s\\n\" '[$repo]' 'Server = https://mirrors.tuna.tsinghua.edu.cn/$repo/\$arch' \\
						| sudo tee -a /etc/pacman.conf"
			fi
		done
	fi

	if grep -q '^\s*#\s*Color$' /etc/pacman.conf; then
		echo_and_eval "sudo sed -i -E 's/^(\\s*)#\\s*Color$/\\1Color/g' /etc/pacman.conf"
	fi

	if $SET_MIRRORS; then
		echo_and_eval 'sudo pacman-mirrors --country China --method rank'
	fi
	echo_and_eval 'sudo pacman -Syy'

	if $SET_MIRRORS; then
		echo_and_eval 'sudo pacman-key --recv-keys 7931B6D628C8D3BA'
		echo_and_eval 'sudo pacman-key --finger 7931B6D628C8D3BA'
		echo_and_eval 'sudo pacman-key --lsign-key 7931B6D628C8D3BA'
		echo_and_eval 'yes | sudo pacman -S archlinuxcn-keyring --needed'
	fi

	# Install and setup shells
	echo_and_eval 'yes | sudo pacman -S zsh --needed'

	if ! grep -qF '/usr/bin/zsh' /etc/shells; then
		echo_and_eval 'echo "/usr/bin/zsh" | sudo tee -a /etc/shells'
	fi

	# Install packages
	echo_and_eval 'yes | sudo pacman -S bash-completion wget curl git git-lfs gvim tmux --needed'
	echo_and_eval 'yes | sudo pacman -S ranger fd bat highlight ripgrep git-extras shfmt shellcheck --needed'
	echo_and_eval 'yes | sudo pacman -S htop openssh net-tools exfat-utils tree colordiff diff-so-fancy xclip --needed'
	echo_and_eval 'yes | sudo pacman -S gcc gdb clang llvm lldb make cmake automake autoconf ruby --needed'
	echo_and_eval 'yes | sudo pacman -Scc'

	echo_and_eval 'sudo systemctl start sshd'
	echo_and_eval 'sudo systemctl enable sshd.service'
fi

# Change default shell to Zsh
if [[ "$(basename "$SHELL")" != "zsh" ]]; then
	if grep -qF '/usr/bin/zsh' /etc/shells; then
		echo_and_eval 'chsh -s /usr/bin/zsh'
	elif grep -qF '/bin/zsh' /etc/shells; then
		echo_and_eval 'chsh -s /bin/zsh'
	fi
fi

echo_and_eval 'cd "$HOME"'

# Configurations for Git
export GIT_HTTP_LOW_SPEED_LIMIT=0
export GIT_HTTP_LOW_SPEED_TIME=999999

backup_dotfiles .gitconfig .dotfiles/.gitconfig

git config --global core.compression -1
git config --global core.excludesfile '~/.gitignore_global'
git config --global core.eol lf
git config --global core.autocrlf false
git config --global core.editor vim
git config --global diff.tool vimdiff
git config --global diff.guitool gvimdiff
git config --global diff.algorithm histogram
git config --global difftool.prompt false
git config --global merge.tool vimdiff
git config --global merge.guitool gvimdiff
git config --global mergetool.prompt false
git config --global http.postBuffer 524288000
git config --global fetch.prune true
git config --global fetch.parallel 0
git config --global submodule.recurse true
git config --global submodule.fetchJobs 0
git config --global filter.lfs.clean 'git-lfs clean -- %f'
git config --global filter.lfs.smudge 'git-lfs smudge -- %f'
git config --global filter.lfs.process 'git-lfs filter-process'
git config --global filter.lfs.required true
git config --global color.ui true
if [[ -x "$(command -v diff-so-fancy)" ]]; then
	diff-so-fancy --set-defaults
fi

mv -f .gitconfig .dotfiles/.gitconfig
ln -sf .dotfiles/.gitconfig .

# Install Oh-My-Zsh
export ZSH="${ZSH:-"$HOME/.oh-my-zsh"}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-"$ZSH/custom"}"
export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-"$ZSH/cahce"}"

if [[ -d "$ZSH/.git" && -f "$ZSH/tools/upgrade.sh" ]]; then
	rm -f "$ZSH_CACHE_DIR/.zsh-update" 2>/dev/null
	zsh "$ZSH/tools/check_for_upgrade.sh" 2>/dev/null
	echo_and_eval 'zsh "$ZSH/tools/upgrade.sh" 2>&1'
else
	echo_and_eval 'git clone -c core.eol=lf -c core.autocrlf=false \
			-c fsck.zeroPaddedFilemode=ignore \
			-c fetch.fsck.zeroPaddedFilemode=ignore \
			-c receive.fsck.zeroPaddedFilemode=ignore \
			--depth=1 https://github.com/robbyrussell/oh-my-zsh.git "${ZSH:-"$HOME/.oh-my-zsh"}" 2>&1'
	rm -f "$HOME"/.zcompdump* 2>/dev/null
fi

# Install Powerlevel10k theme
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k/.git" ]]; then
	echo_and_eval 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" 2>&1'
else
	echo_and_eval 'git -C "$ZSH_CUSTOM/themes/powerlevel10k" pull --ff-only 2>&1'
fi

# Install Zsh plugins
for plugin in zsh-{syntax-highlighting,autosuggestions,completions}; do
	if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin/.git" ]]; then
		echo_and_eval "git clone --depth=1 https://github.com/zsh-users/${plugin}.git \"\$ZSH_CUSTOM/plugins/$plugin\" 2>&1"
	else
		echo_and_eval "git -C \"\$ZSH_CUSTOM/plugins/$plugin\" pull --ff-only 2>&1"
	fi
done

# Install fzf
if [[ ! -d "$HOME/.fzf" ]]; then
	echo_and_eval 'git clone --depth=1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>&1'
else
	echo_and_eval 'git -C "$HOME/.fzf" pull --ff-only 2>&1'
fi
echo_and_eval '"$HOME/.fzf/install" --key-bindings --completion --no-update-rc'

# Configurations for RubyGems
backup_dotfiles .gemrc .dotfiles/.gemrc

cat >.dotfiles/.gemrc <<EOF
---
:backtrace: false
:bulk_threshold: 1000
:update_sources: true
:verbose: true
:concurrent_downloads: 8
EOF
if $SET_MIRRORS; then
	cat >>.dotfiles/.gemrc <<EOF
:sources:
- https://mirrors.tuna.tsinghua.edu.cn/rubygems/
EOF
fi

ln -sf .dotfiles/.gemrc .

# Update RubyGems and install Color LS
if [[ -x "$(command -v ruby)" && -x "$(command -v gem)" ]]; then
	export RUBYOPT="-W0"
	export PATH="$(ruby -r rubygems -e 'puts Gem.dir')/bin:$PATH"
	export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
	if $IS_SUDOER; then
		echo_and_eval 'sudo gem update --system --config-file "$HOME/.gemrc"'
		echo_and_eval 'sudo gem update --config-file "$HOME/.gemrc"'
		echo_and_eval 'sudo gem cleanup --config-file "$HOME/.gemrc"'
	fi
	echo_and_eval 'gem update --user-install'
	echo_and_eval 'gem install colorls --user-install'
	echo_and_eval 'gem cleanup --user-install'
fi

# Configurations for CPAN
export PERL_MB_OPT="--install_base \"$HOME/.perl\""
export PERL_MM_OPT="INSTALL_BASE=\"$HOME/.perl\""
echo_and_eval 'printf "\n\n\n%s\n" "quit" | cpan'
if $SET_MIRRORS; then
	echo_and_eval 'printf "%s\n%s\n%s\n" \
			"o conf urllist https://mirrors.tuna.tsinghua.edu.cn/CPAN/" \
			"o conf commit" \
			"quit" \
			| cpan'
fi
echo_and_eval 'cpan -i local::lib'
echo_and_eval 'eval "$(perl -I$HOME/.perl/lib/perl5 -Mlocal::lib=$HOME/.perl)"'
echo_and_eval 'cpan -i CPAN'
echo_and_eval 'cpan -i Log::Log4perl'
echo_and_eval 'printf "\n%s\n\n" "exit" | cpan -i Term::ReadLine::Perl Term::ReadKey'

# Configurations for Zsh
backup_dotfiles .dotfiles/.zshrc

cat >.dotfiles/.zshrc <<EOF
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
if [[ -d "\$HOME/.local/bin" ]]; then
	export PATH="\$HOME/.local/bin:\$PATH"
fi

# Set C_INCLUDE_PATH and CPLUS_INCLUDE_PATH so it includes user's private include if it exists
if [[ -d "\$HOME/.local/include" ]]; then
	export C_INCLUDE_PATH="\$HOME/.local/include:\$C_INCLUDE_PATH"
	export CPLUS_INCLUDE_PATH="\$HOME/.local/include:\$CPLUS_INCLUDE_PATH"
fi

# Set LIBRARY_PATH and LD_LIBRARY_PATH so it includes user's private lib if it exists
if [[ -d "\$HOME/.local/lib" ]]; then
	export LIBRARY_PATH="\$HOME/.local/lib:\$LIBRARY_PATH"
	export LD_LIBRARY_PATH="\$HOME/.local/lib:\$LD_LIBRARY_PATH"
fi
if [[ -d "\$HOME/.local/lib64" ]]; then
	export LIBRARY_PATH="\$HOME/.local/lib64:\$LIBRARY_PATH"
	export LD_LIBRARY_PATH="\$HOME/.local/lib64:\$LD_LIBRARY_PATH"
fi

# User specific environment
export TERM="xterm-256color"

# Locale
export LC_ALL="en_US.utf8"

# Compilers
export CC="/usr/bin/gcc"
export CXX="/usr/bin/g++"
export FC="/usr/bin/gfortran"
export OMPI_CC="\$CC" MPICH_CC="\$CC"
export OMPI_CXX="\$CXX" MPICH_CXX="\$CXX"
export OMPI_FC="\$FC" MPICH_FC="\$FC"

# Anaconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="\$(CONDA_REPORT_ERRORS=false "\$HOME/$CONDA_DIR/bin/conda" shell.zsh hook 2>/dev/null)"
if [[ \$? -eq 0 ]]; then
	eval "\$__conda_setup"
else
	if [[ -f "\$HOME/$CONDA_DIR/etc/profile.d/conda.sh" ]]; then
		. "\$HOME/$CONDA_DIR/etc/profile.d/conda.sh"
	else
		export PATH="\$HOME/$CONDA_DIR/bin:\$PATH"
	fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Ruby
if [[ -x "\$(command -v ruby)" && -x "\$(command -v gem)" ]]; then
	export RUBYOPT="-W0"
	export PATH="\$(ruby -r rubygems -e 'puts Gem.dir')/bin:\$PATH"
	export PATH="\$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:\$PATH"
fi

# Perl
eval "\$(perl -I\$HOME/.perl/lib/perl5 -Mlocal::lib=\$HOME/.perl)"

# fzf
if [[ -f "\$HOME/.fzf.zsh" ]]; then
	source "\$HOME/.fzf.zsh"
fi
if [[ -x "\$(command -v fd)" ]]; then
	export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --no-ignore-vcs --exclude '.git' --color=always"
	export FZF_CTRL_T_COMMAND="\$FZF_DEFAULT_COMMAND"
fi
FZF_PREVIEW_COMMAND="(bat --color=always {} || highlight -O ansi {} || cat {}) 2>/dev/null | head -100"
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --ansi --preview='\${FZF_PREVIEW_COMMAND}'"

# bat
export BAT_THEME="Monokai Extended"

# Remove duplicate entries
function __remove_duplicate() {
	local SEP NAME VALUE
	SEP="\$1"
	NAME="\$2"
	VALUE="\$(
		eval "printf \\"%s\\" \\"\\\$\$NAME\\"" | awk -v RS="\$SEP" \\
			'BEGIN {
				idx = 0;
				delete flag;
				flag[""] = 1;
			}
			{
				if (!(flag[\$0]++))
					printf("%s%s", (!(idx++) ? "" : RS), \$0);
			}'
	)"
	if [[ -n "\$VALUE" ]]; then
		export "\$NAME"="\$VALUE"
	else
		unset "\$NAME"
	fi
}
__remove_duplicate ':' PATH
__remove_duplicate ':' C_INCLUDE_PATH
__remove_duplicate ':' CPLUS_INCLUDE_PATH
__remove_duplicate ':' LIBRARY_PATH
__remove_duplicate ':' LD_LIBRARY_PATH
unset -f __remove_duplicate

# Utilities
if [[ -f "\$HOME/.dotfiles/utilities.sh" ]]; then
	. "\$HOME/.dotfiles/utilities.sh"
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

# Powerlevel10k configrations
POWERLEVEL9K_MODE="nerdfont-complete"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%K{white}%F{black} \\ue795 \\uf155 %f%k%F{white}\\ue0b0%f "
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
	vscode
)

ZSH_COLORIZE_STYLE="monokai"
ZSH_DISABLE_COMPFIX=true

source "\$ZSH/oh-my-zsh.sh"

# User configuration

# export MANPATH="/usr/local/man:\$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n "\$SSH_CONNECTION" ]]; then
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
# For a full list of active aliases, run \$(alias).
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set personal aliases
alias lsa='ls -A'
alias l='ls -alh'
alias ll='ls -lh'
alias la='ls -Alh'

if [[ -z "\$ZSH_PUREPOWER" ]]; then
	# Setup Color LS
	if [[ -x "\$(command -v ruby)" && -x "\$(command -v gem)" ]]; then
		if gem list --silent --installed colorls; then
			source "\$(dirname "\$(gem which colorls)")"/tab_complete.sh
			alias ls='colorls --sd --gs'
		fi
	fi
else
	# Use Powerlevel10k purepower theme
	source "\$ZSH_CUSTOM/themes/powerlevel10k/config/p10k-lean.zsh"
	POWERLEVEL9K_MODE="compatible"
	POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
	POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs virtualenv anaconda pyenv time)
	POWERLEVEL9K_TRANSIENT_PROMPT="same-dir"
	p10k reload
fi
EOF

ln -sf .dotfiles/.zshrc .

# Configurations for Zsh purepower
SHEBANG='#!/bin/sh'
COMMAND='ZSH_PUREPOWER=true exec /usr/bin/zsh "$@"'
cat >"$TMP_DIR/zsh-purepower" <<EOF
${SHEBANG}
${COMMAND}
EOF
if $IS_SUDOER; then
	if [[ ! -d "/usr/local/bin" ]]; then
		echo_and_eval 'sudo mkdir -p "/usr/local/bin"'
	fi
	if [[ ! -x "/usr/local/bin/zsh-purepower" || -L "/usr/local/bin/zsh-purepower" ]] ||
		! diff -EB "/usr/local/bin/zsh-purepower" "$TMP_DIR/zsh-purepower" &>/dev/null; then
		if [[ -f "/usr/local/bin/zsh-purepower" ]]; then
			echo_and_eval 'sudo rm -f /usr/local/bin/zsh-purepower'
		fi
		echo_and_eval "printf \"%s\\n\" '$SHEBANG' '$COMMAND' | sudo tee /usr/local/bin/zsh-purepower"
		echo_and_eval 'sudo chmod a+x /usr/local/bin/zsh-purepower'
	fi
	if ! grep -qF '/usr/local/bin/zsh-purepower' /etc/shells; then
		echo_and_eval 'echo "/usr/local/bin/zsh-purepower" | sudo tee -a /etc/shells'
	fi
else
	mkdir -p "$HOME/.local/bin"
	echo_and_eval "cp -f \"$TMP_DIR/zsh-purepower\" \"\$HOME/.local/bin/zsh-purepower\""
	chmod +x "$HOME/.local/bin/zsh-purepower"
fi

# Add utility script file
backup_dotfiles .dotfiles/utilities.sh

cat >.dotfiles/utilities.sh <<EOF
#!/usr/bin/env bash

function echo_and_eval() {
	printf "%s" "\$@" | awk -f <(
		cat - <<-EOD
			BEGIN {
				BOLD = "\\\\033[1m"
				UNDERLINE = "\\\\033[4m";
				RED = "\\\\033[31m";
				GREEN = "\\\\033[32m";
				YELLOW = "\\\\033[33m";
				WHITE = "\\\\033[37m";
				RESET = "\\\\033[0m";
				idx = 0;
				in_string = 0;
				double_quoted = 1;
				printf("%s\\\$", BOLD WHITE);
			}
			{
				for (i = 1; i <= NF; ++i) {
					style = WHITE;
					style_post = WHITE;
					if (!in_string) {
						if (\\\$i ~ /^-/)
							style = YELLOW;
						else if (\\\$i == "sudo" && idx == 0) {
							style = UNDERLINE GREEN;
							style_post = RESET BOLD WHITE;
						}
						else if (\\\$i ~ /^[12&]?>>?/)
							style = RED;
						else {
							++idx;
							if (\\\$i ~ /^"/) {
								in_string = 1;
								double_quoted = 1;
							}
							else if (\\\$i ~ /^'/) {
								in_string = 1;
								double_quoted = 0;
							}
							if (idx == 1)
								style = GREEN;
						}
					}
					if (in_string) {
						if ((double_quoted && \\\$i ~ /";?\\\$/ && \\\$i !~ /\\\\\\\\";?\\\$/) || (!double_quoted && \\\$i ~ /';?\\\$/))
							in_string = 0;
					}
					if (\\\$i ~ /;\\\$/ || \\\$i == "|" || \\\$i == "||" || \\\$i == "&&") {
						if (!in_string) {
							idx = 0;
							if (\\\$i !~ /;\\\$/)
								style = RED;
						}
					}
					if (\\\$i ~ /;\\\$/)
						printf(" %s%s%s;%s", style, substr(\\\$i, 1, length(\\\$i) - 1), (in_string ? WHITE : RED), style_post);
					else
						printf(" %s%s%s", style, \\\$i, style_post);
					if (\\\$i == "\\\\\\\\")
						printf("\\\\n\\\\t");
				}
			}
			END {
				printf("%s\\\\n", RESET);
			}
		EOD
	)
	eval "\$@"
}

function upgrade_manjaro() {
	# Upgrade packages
	echo_and_eval 'sudo pacman -Syy'
	echo_and_eval 'yes | sudo pacman -Syu'

	# Remove unused packages
	echo_and_eval 'sudo paccache -ruk0'

	# Clean up cache
	echo_and_eval 'yes | sudo pacman -Scc'
}

function upgrade_ohmyzsh() {
	local REPOS repo

	# Set oh-my-zsh installation path
	export ZSH="\${ZSH:-"\$HOME/.oh-my-zsh"}"
	export ZSH_CUSTOM="\${ZSH_CUSTOM:-"\$ZSH/custom"}"
	export ZSH_CACHE_DIR="\${ZSH_CACHE_DIR:-"\$ZSH/cache"}"

	# Upgrade oh my zsh
	rm -f "\$ZSH_CACHE_DIR/.zsh-update" 2>/dev/null
	zsh "\$ZSH/tools/check_for_upgrade.sh" 2>/dev/null
	echo_and_eval 'zsh "\$ZSH/tools/upgrade.sh"'

	# Upgrade themes and plugins
	REPOS=(\$(
		cd "\$ZSH_CUSTOM"
		find -L . -mindepth 3 -maxdepth 3 -not -empty -type d -name '.git' |
			sed -E 's#^\\./(.*)/\\.git\$#\\1#'
	))
	for repo in "\${REPOS[@]}"; do
		echo_and_eval "git -C \\"\\\$ZSH_CUSTOM/\$repo\\" pull --ff-only"
	done
}

function upgrade_fzf() {
	echo_and_eval 'git -C "\$HOME/.fzf" pull --ff-only'
	echo_and_eval '"\$HOME/.fzf/install" --key-bindings --completion --no-update-rc'
}

function upgrade_vim() {
	echo_and_eval 'vim -c "PlugUpgrade | PlugUpdate | quitall"'
}

function upgrade_gems() {
	if groups | grep -qE '(wheel|root)'; then
		echo_and_eval 'sudo gem update --system --config-file "\$HOME/.gemrc"'
		echo_and_eval 'sudo gem update --config-file "\$HOME/.gemrc"'
		echo_and_eval 'sudo gem cleanup --config-file "\$HOME/.gemrc"'
	fi
	echo_and_eval 'gem update --user-install'
	echo_and_eval 'gem cleanup --user-install'
}

function upgrade_cpan() {
	echo_and_eval 'cpan -u'
}

function upgrade_conda() {
	local ENVS env

	# Upgrade Conda
	echo_and_eval 'conda update conda --name base --yes'

	# Upgrade Conda packages in each environment
	ENVS=(base \$(
		cd "\$(conda info --base)/envs"
		find -L . -mindepth 1 -maxdepth 1 -not -empty \\( -type d -or -type l \\) |
			sed -E 's#^\\./(.*)\$#\\1#'
	))
	for env in "\${ENVS[@]}"; do
		echo_and_eval "conda update --all --name \$env --yes"
		if conda list --full-name anaconda --name "\$env" | grep -q '^anaconda[^-]'; then
			echo_and_eval "conda update anaconda --name \$env --yes"
		fi
	done

	# Clean up Conda cache
	echo_and_eval 'conda clean --all --yes'
}

function upgrade_packages() {
	if groups | grep -qE '(wheel|root)'; then
		upgrade_manjaro
	fi
	upgrade_ohmyzsh
	upgrade_fzf
	if [[ -x "\$(command -v vim)" ]]; then
		upgrade_vim
	fi
	if [[ -x "\$(command -v ruby)" && -x "\$(command -v gem)" ]]; then
		upgrade_gems
	fi
	# upgrade_cpan
	# upgrade_conda

	if [[ -n "\$ZSH_VERSION" ]]; then
		if [[ -f "\${ZDOTDIR:-"\$HOME"}/.zshrc" ]]; then
			source "\${ZDOTDIR:-"\$HOME"}/.zshrc"
		fi
	elif [[ -n "\$BASH_VERSION" ]]; then
		if [[ -f "\$HOME/.bash_profile" ]]; then
			source "\$HOME/.bash_profile"
		fi
	fi
}

function set_proxy() {
	local PROXY_HOST="\${1:-"127.0.0.1"}"
	local HTTP_PORT="\${2:-"7890"}"
	local HTTPS_PORT="\${3:-"7890"}"
	local FTP_PORT="\${4:-"7890"}"
	local SOCKS_PORT="\${5:-"7891"}"

	if [[ -x "\$(command -v /usr/bin/gsettings)" ]]; then
		/usr/bin/gsettings set org.gnome.system.proxy mode 'manual'
		/usr/bin/gsettings set org.gnome.system.proxy.http host "\$PROXY_HOST"
		/usr/bin/gsettings set org.gnome.system.proxy.http port "\$HTTP_PORT"
		/usr/bin/gsettings set org.gnome.system.proxy.https host "\$PROXY_HOST"
		/usr/bin/gsettings set org.gnome.system.proxy.https port "\$HTTPS_PORT"
		/usr/bin/gsettings set org.gnome.system.proxy.ftp host "\$PROXY_HOST"
		/usr/bin/gsettings set org.gnome.system.proxy.ftp port "\$FTP_PORT"
		/usr/bin/gsettings set org.gnome.system.proxy.socks host "\$PROXY_HOST"
		/usr/bin/gsettings set org.gnome.system.proxy.socks port "\$SOCKS_PORT"
	fi

	export http_proxy="http://\${PROXY_HOST}:\${HTTP_PORT}"
	export https_proxy="http://\${PROXY_HOST}:\${HTTPS_PORT}"
	export ftp_proxy="http://\${PROXY_HOST}:\${FTP_PORT}"
	export all_proxy="socks5://\${PROXY_HOST}:\${SOCKS_PORT}"
	export HTTP_PROXY="\$http_proxy"
	export HTTPS_PROXY="\$https_proxy"
	export FTP_PROXY="\$ftp_proxy"
	export ALL_PROXY="\$all_proxy"
}

function reset_proxy() {
	if [[ -x "\$(command -v /usr/bin/gsettings)" ]]; then
		/usr/bin/gsettings set org.gnome.system.proxy mode 'none'
		/usr/bin/gsettings set org.gnome.system.proxy.http host '127.0.0.1'
		/usr/bin/gsettings set org.gnome.system.proxy.http port 8080
		/usr/bin/gsettings set org.gnome.system.proxy.https host '127.0.0.1'
		/usr/bin/gsettings set org.gnome.system.proxy.https port 0
		/usr/bin/gsettings set org.gnome.system.proxy.ftp host '127.0.0.1'
		/usr/bin/gsettings set org.gnome.system.proxy.ftp port 0
		/usr/bin/gsettings set org.gnome.system.proxy.socks host '127.0.0.1'
		/usr/bin/gsettings set org.gnome.system.proxy.socks port 0
	fi

	unset https_proxy
	unset http_proxy
	unset ftp_proxy
	unset all_proxy
	unset HTTPS_PROXY
	unset HTTP_PROXY
	unset FTP_PROXY
	unset ALL_PROXY
}

function auto_reannounce_trackers() {
	local TIMES="\${1:-60}"
	local INTERVAL="\${2:-60}"
	local TORRENT CMD t r

	echo -ne "\\033[?25l"

	for ((t = 0; t <= TIMES; ++t)); do
		if [[ \$((t % 5)) != 0 ]]; then
			TORRENT="active"
		else
			TORRENT="all"
		fi
		CMD="transmission-remote --torrent \$TORRENT --reannounce"
		eval "\$CMD" 1>/dev/null
		for ((r = INTERVAL - 1; r >= 0; --r)); do
			echo -ne "\$CMD (\$t/\$TIMES, next reannounce in \${r}s)\\033[K\\r"
			sleep 1
		done
	done

	echo -ne "\\033[K\\033[?25h"
}
EOF

# Configurations for Bash
backup_dotfiles .bashrc .dotfiles/.bashrc

if ! grep -qF 'shopt -q login_shell' .bashrc; then
	cat >>.bashrc <<EOF

# Always source ~/.bash_profile
if ! shopt -q login_shell; then
	# Include ~/.bash_profile if it exists
	if [[ -f "\$HOME/.bash_profile" ]]; then
		. "\$HOME/.bash_profile"
	elif [[ -f "\$HOME/.profile" ]]; then
		. "\$HOME/.profile"
	fi
fi
EOF
fi

mv -f .bashrc .dotfiles/.bashrc
ln -sf .dotfiles/.bashrc .

backup_dotfiles .bash_profile .dotfiles/.bash_profile

cat >.dotfiles/.bash_profile <<EOF
#
# ~/.bash_profile
#
# See /usr/share/doc/bash/examples/startup-files for examples.
# The files are located in the bash-doc package.

# The default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# If running bash as login shell
if [[ -n "\$BASH_VERSION" ]] && shopt -q login_shell; then
	# Include ~/.bashrc if it exists
	if [[ -f "\$HOME/.bashrc" ]]; then
		. "\$HOME/.bashrc"
	fi
fi

# Set PATH so it includes user's private bin if it exists
if [[ -d "\$HOME/.local/bin" ]]; then
	export PATH="\$HOME/.local/bin:\$PATH"
fi

# Set C_INCLUDE_PATH and CPLUS_INCLUDE_PATH so it includes user's private include if it exists
if [[ -d "\$HOME/.local/include" ]]; then
	export C_INCLUDE_PATH="\$HOME/.local/include:\$C_INCLUDE_PATH"
	export CPLUS_INCLUDE_PATH="\$HOME/.local/include:\$CPLUS_INCLUDE_PATH"
fi

# Set LIBRARY_PATH and LD_LIBRARY_PATH so it includes user's private lib if it exists
if [[ -d "\$HOME/.local/lib" ]]; then
	export LIBRARY_PATH="\$HOME/.local/lib:\$LIBRARY_PATH"
	export LD_LIBRARY_PATH="\$HOME/.local/lib:\$LD_LIBRARY_PATH"
fi
if [[ -d "\$HOME/.local/lib64" ]]; then
	export LIBRARY_PATH="\$HOME/.local/lib64:\$LIBRARY_PATH"
	export LD_LIBRARY_PATH="\$HOME/.local/lib64:\$LD_LIBRARY_PATH"
fi

# User specific environment and startup programs
export TERM="xterm-256color"
export PS1='[\\[\\e[1;33m\\]\\u\\[\\e[0m\\]@\\[\\e[1;32m\\]\\h\\[\\e[0m\\]:\\[\\e[1;35m\\]\\w\\[\\e[0m\\]]\\\$ '

# Locale
export LC_ALL="en_US.utf8"

# Compilers
export CC="/usr/bin/gcc"
export CXX="/usr/bin/g++"
export FC="/usr/bin/gfortran"
export OMPI_CC="\$CC" MPICH_CC="\$CC"
export OMPI_CXX="\$CXX" MPICH_CXX="\$CXX"
export OMPI_FC="\$FC" MPICH_FC="\$FC"

# Anaconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="\$(CONDA_REPORT_ERRORS=false "\$HOME/$CONDA_DIR/bin/conda" shell.bash hook 2>/dev/null)"
if [[ \$? -eq 0 ]]; then
	eval "\$__conda_setup"
else
	if [[ -f "\$HOME/$CONDA_DIR/etc/profile.d/conda.sh" ]]; then
		. "\$HOME/$CONDA_DIR/etc/profile.d/conda.sh"
	else
		export PATH="\$HOME/$CONDA_DIR/bin:\$PATH"
	fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Ruby
if [[ -x "\$(command -v ruby)" && -x "\$(command -v gem)" ]]; then
	export RUBYOPT="-W0"
	export PATH="\$(ruby -r rubygems -e 'puts Gem.dir')/bin:\$PATH"
	export PATH="\$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:\$PATH"
fi

# Perl
eval "\$(perl -I\$HOME/.perl/lib/perl5 -Mlocal::lib=\$HOME/.perl)"

# fzf
if [[ -f "\$HOME/.fzf.bash" ]]; then
	source "\$HOME/.fzf.bash"
fi
if [[ -x "\$(command -v fd)" ]]; then
	export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --no-ignore-vcs --exclude '.git' --color=always"
	export FZF_CTRL_T_COMMAND="\$FZF_DEFAULT_COMMAND"
fi
FZF_PREVIEW_COMMAND="(bat --color=always {} || highlight -O ansi {} || cat {}) 2>/dev/null | head -100"
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --ansi --preview='\${FZF_PREVIEW_COMMAND}'"

# bat
export BAT_THEME="Monokai Extended"

# Remove duplicate entries
function __remove_duplicate() {
	local SEP NAME VALUE
	SEP="\$1"
	NAME="\$2"
	VALUE="\$(
		eval "printf \\"%s\\" \\"\\\$\$NAME\\"" | awk -v RS="\$SEP" \\
			'BEGIN {
				idx = 0;
				delete flag;
				flag[""] = 1;
			}
			{
				if (!(flag[\$0]++))
					printf("%s%s", (!(idx++) ? "" : RS), \$0);
			}'
	)"
	if [[ -n "\$VALUE" ]]; then
		export "\$NAME"="\$VALUE"
	else
		unset "\$NAME"
	fi
}
__remove_duplicate ':' PATH
__remove_duplicate ':' C_INCLUDE_PATH
__remove_duplicate ':' CPLUS_INCLUDE_PATH
__remove_duplicate ':' LIBRARY_PATH
__remove_duplicate ':' LD_LIBRARY_PATH
unset -f __remove_duplicate

# Utilities
if [[ -f "\$HOME/.dotfiles/utilities.sh" ]]; then
	. "\$HOME/.dotfiles/utilities.sh"
fi

# Bash completion
if [[ -r "/etc/profile.d/bash_completion.sh" ]]; then
	. "/etc/profile.d/bash_completion.sh"
elif [[ -r "/usr/share/bash-completion/bash_completion" ]]; then
	. "/usr/share/bash-completion/bash_completion"
elif [[ -r "/etc/bash_completion" ]]; then
	. "/etc/bash_completion"
fi
EOF

ln -sf .dotfiles/.bash_profile .

# Configurations for Vim
backup_dotfiles .vimrc .dotfiles/.vimrc

GUI_FONT='DejaVuSansMono\ Nerd\ Font\ Mono\ 10'
if $IN_WSL; then
	GUI_FONT='DejaVuSansMono\ NF\ 10'
fi
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
set smarttab
set tabstop=4
set shiftwidth=4
set expandtab
set list
set listchars=tab:»\\ ,trail:·
set conceallevel=2
set concealcursor=""
set number
set ruler
set colorcolumn=80,100,120,140
set cursorline
set foldenable
set foldmethod=indent
set foldlevel=10
set scrolloff=3
set sidescroll=10
set linebreak
set wrap
set showmatch
set hlsearch
execute "nohlsearch"
set incsearch
set ignorecase
set smartcase
set autochdir
set visualbell
set autoread
set updatetime=200
set showcmd
set wildmenu
set wildmode=longest:list,full
set completeopt=longest,menu
set background=dark
set t_Co=256
set guifont=${GUI_FONT}
colorscheme monokai

if &term =~ "xterm"
    let &t_SI = "\\<Esc>]50;CursorShape=1\\x7"
    let &t_SR = "\\<Esc>]50;CursorShape=2\\x7"
    let &t_EI = "\\<Esc>]50;CursorShape=0\\x7"
endif

autocmd GUIEnter * set lines=50 columns=160

autocmd GUIEnter * set spell spelllang=en_us

autocmd BufReadPost * if line("'\\"") > 1 && line("'\\"") <= line("\$") | execute "normal! g'\\"" | endif
autocmd BufWritePre,FileWritePre * RemoveTrailingSpaces
autocmd Filetype sh,zsh,gitconfig,c,cpp,make,go set noexpandtab
autocmd FileType vim,tex let b:autoformat_autoindent = 0

let g:NERDTreeMouseMode = 2
let g:NERDTreeShowBookmarks = 1
let g:NERDTreeShowFiles = 1
let g:NERDTreeShowHidden = 1
let g:NERDTreeShowLineNumbers = 0
let g:NERDTreeWinPos = 'left'
let g:NERDTreeWinSize = 31
let g:NERDTreeNotificationThreshold = 200
let s:NERDTreeClosedByResizing = !&diff
function s:NERDTreeAutoToggle(minbufwidth = 80)
    if !(exists('b:NERDTree') && b:NERDTree.isTabTree())
        let NERDTreeIsOpen = (g:NERDTree.ExistsForTab() && g:NERDTree.IsOpen())
        let width = winwidth('%')
        let numberwidth = ((&number || &relativenumber) ? max([&numberwidth, strlen(line('\$')) + 1]) : 0)
        let signwidth = ((&signcolumn == 'yes' || &signcolumn == 'auto') ? 2 : 0)
        let foldwidth = &foldcolumn
        let bufwidth = width - numberwidth - foldwidth - signwidth
        if bufwidth >= a:minbufwidth + (g:NERDTreeWinSize + 1) * (1 - NERDTreeIsOpen)
            if !NERDTreeIsOpen && s:NERDTreeClosedByResizing
                if str2nr(system('find "' . getcwd() . '" -mindepth 1 -maxdepth 1 | wc -l')) <= g:NERDTreeNotificationThreshold
                    NERDTree
                    wincmd p
                    let s:NERDTreeClosedByResizing = 0
                endif
            endif
        elseif NERDTreeIsOpen && !s:NERDTreeClosedByResizing
            NERDTreeClose
            let s:NERDTreeClosedByResizing = 1
        endif
    endif
endfunction
autocmd VimEnter,VimResized * call s:NERDTreeAutoToggle(80)
autocmd BufEnter * if winnr('\$') == 1 && (exists('b:NERDTree') && b:NERDTree.isTabTree()) | quit | endif

let g:airline#extensions#tabline#enabled = 1

let g:bufferline_echo = 0

if &diff
    let &diffexpr = 'EnhancedDiff#Diff("git diff", "--diff-algorithm=histogram")'
endif
autocmd VimResized * if &diff | wincmd = | endif

let g:indentLine_char_list = ['|', '¦', '┆', '┊']

let g:fzf_buffers_jump = 1
let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'
let g:fzf_tags_command = 'ctags -R'
let g:fzf_commands_expect = 'alt-enter,ctrl-x'

let g:indentLine_setConceal = 0

let g:rainbow_active = 1

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_loc_list_height = 5
let g:syntastic_check_on_wq = 0
autocmd GUIEnter * let g:syntastic_check_on_open = 1

let g:tex_flavor = 'latex'

if !exists('\$SSH_CONNECTION')
    let g:mkdp_auto_start = 1
endif

call plug#begin('~/.vim/plugged')
    Plug 'flazz/vim-colorschemes'
    Plug 'mhinz/vim-startify'
    Plug 'scrooloose/nerdtree'
    Plug 'scrooloose/nerdcommenter'
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
    Plug 'ryanoasis/vim-devicons'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'bling/vim-bufferline'
    Plug 'chrisbra/vim-diff-enhanced'
    Plug 'yggdroot/indentline'
    Plug 'luochen1990/rainbow'
    Plug 'jaxbot/semantic-highlight.vim'
    Plug 'chrisbra/Colorizer'
    Plug 'psliwka/vim-smoothie'
    Plug 'jiangmiao/auto-pairs'
    Plug 'tpope/vim-surround'
    Plug 'mg979/vim-visual-multi'
    Plug 'mbbill/undotree'
    Plug 'airblade/vim-gitgutter'
    Plug 'tpope/vim-fugitive'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf' }
    Plug 'junegunn/fzf.vim'
    Plug 'Chiel92/vim-autoformat'
    Plug 'vim-syntastic/syntastic'
    Plug 'SirVer/ultisnips'
    Plug 'honza/vim-snippets'
    Plug 'PProvost/vim-ps1'
    Plug 'elzr/vim-json'
    Plug 'godlygeek/tabular'
    Plug 'plasticboy/vim-markdown'
    Plug 'iamcco/markdown-preview.nvim'
    Plug 'lervag/vimtex'
call plug#end()
EOF

ln -sf .dotfiles/.vimrc .

# Add Vim Monokai color theme
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

highlight Cursor                       ctermfg=235   ctermbg=231  cterm=NONE         guifg=#272822 guibg=#F8F8F0 gui=NONE
highlight Visual                       ctermfg=NONE  ctermbg=59   cterm=NONE         guifg=NONE    guibg=#49483E gui=NONE
highlight CursorLine                   ctermfg=NONE  ctermbg=237  cterm=NONE         guifg=NONE    guibg=#3C3D37 gui=NONE
highlight CursorColumn                 ctermfg=NONE  ctermbg=237  cterm=NONE         guifg=NONE    guibg=#3C3D37 gui=NONE
highlight ColorColumn                  ctermfg=NONE  ctermbg=237  cterm=NONE         guifg=NONE    guibg=#3C3D37 gui=NONE
highlight LineNr                       ctermfg=102   ctermbg=237  cterm=NONE         guifg=#90908A guibg=#3C3D37 gui=NONE
highlight VertSplit                    ctermfg=241   ctermbg=241  cterm=NONE         guifg=#64645E guibg=#64645E gui=NONE
highlight MatchParen                   ctermfg=197   ctermbg=NONE cterm=underline    guifg=#F92672 guibg=NONE    gui=underline
highlight StatusLine                   ctermfg=231   ctermbg=241  cterm=bold         guifg=#F8F8F2 guibg=#64645E gui=bold
highlight StatusLineNC                 ctermfg=231   ctermbg=241  cterm=NONE         guifg=#F8F8F2 guibg=#64645E gui=NONE
highlight Pmenu                        ctermfg=NONE  ctermbg=238  cterm=NONE         guifg=NONE    guibg=#35342D gui=NONE
highlight PmenuSel                     ctermfg=NONE  ctermbg=59   cterm=NONE         guifg=NONE    guibg=#49483E gui=NONE
highlight IncSearch       term=reverse ctermfg=193   ctermbg=16   cterm=reverse      guifg=#C4BE89 guibg=#000000 gui=reverse
highlight Search          term=reverse ctermfg=231   ctermbg=24   cterm=NONE         guifg=#F8F8F2 guibg=#204A87 gui=NONE
highlight Directory                    ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight Folded                       ctermfg=242   ctermbg=235  cterm=NONE         guifg=#75715E guibg=#272822 gui=NONE
highlight SignColumn                   ctermfg=NONE  ctermbg=237  cterm=NONE         guifg=NONE    guibg=#3C3D37 gui=NONE
highlight Normal                       ctermfg=231   ctermbg=235  cterm=NONE         guifg=#F8F8F2 guibg=#272822 gui=NONE
highlight Boolean                      ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight Character                    ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight Comment                      ctermfg=242   ctermbg=NONE cterm=NONE         guifg=#75715E guibg=NONE    gui=NONE
highlight Conditional                  ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight Constant                     ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight Define                       ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight DiffAdd                      ctermfg=231   ctermbg=64   cterm=bold         guifg=#F8F8F2 guibg=#46830C gui=bold
highlight DiffDelete                   ctermfg=88    ctermbg=NONE cterm=NONE         guifg=#8B0807 guibg=NONE    gui=NONE
highlight DiffChange                   ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=#F8F8F2 guibg=#243955 gui=NONE
highlight DiffText                     ctermfg=231   ctermbg=24   cterm=bold         guifg=#F8F8F2 guibg=#204A87 gui=bold
highlight ErrorMsg                     ctermfg=231   ctermbg=197  cterm=NONE         guifg=#F8F8F0 guibg=#F92672 gui=NONE
highlight WarningMsg                   ctermfg=231   ctermbg=197  cterm=NONE         guifg=#F8F8F0 guibg=#F92672 gui=NONE
highlight Float                        ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight Function                     ctermfg=148   ctermbg=NONE cterm=NONE         guifg=#A6E22E guibg=NONE    gui=NONE
highlight Identifier                   ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=italic
highlight Keyword                      ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight Label                        ctermfg=186   ctermbg=NONE cterm=NONE         guifg=#E6DB74 guibg=NONE    gui=NONE
highlight NonText                      ctermfg=59    ctermbg=236  cterm=NONE         guifg=#49483E guibg=#31322C gui=NONE
highlight Number                       ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight Operator                     ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight PreProc                      ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight Special                      ctermfg=231   ctermbg=NONE cterm=NONE         guifg=#F8F8F2 guibg=NONE    gui=NONE
highlight SpecialComment               ctermfg=242   ctermbg=NONE cterm=NONE         guifg=#75715E guibg=NONE    gui=NONE
highlight SpecialKey                   ctermfg=59    ctermbg=236  cterm=NONE         guifg=#49483E guibg=#2C2D27 gui=NONE
highlight Statement                    ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight StorageClass                 ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=italic
highlight String                       ctermfg=186   ctermbg=NONE cterm=NONE         guifg=#E6DB74 guibg=NONE    gui=NONE
highlight Tag                          ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight Title                        ctermfg=231   ctermbg=NONE cterm=bold         guifg=#F8F8F2 guibg=NONE    gui=bold
highlight Todo                         ctermfg=95    ctermbg=NONE cterm=inverse,bold guifg=#75715E guibg=NONE    gui=inverse,bold
highlight Type                         ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight Underlined                   ctermfg=NONE  ctermbg=NONE cterm=underline    guifg=NONE    guibg=NONE    gui=underline
highlight rubyClass                    ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight rubyFunction                 ctermfg=148   ctermbg=NONE cterm=NONE         guifg=#A6E22E guibg=NONE    gui=NONE
highlight rubyInterpolationDelimiter   ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight rubySymbol                   ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight rubyConstant                 ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=italic
highlight rubyStringDelimiter          ctermfg=186   ctermbg=NONE cterm=NONE         guifg=#E6DB74 guibg=NONE    gui=NONE
highlight rubyBlockParameter           ctermfg=208   ctermbg=NONE cterm=NONE         guifg=#FD971F guibg=NONE    gui=italic
highlight rubyInstanceVariable         ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight rubyInclude                  ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight rubyGlobalVariable           ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight rubyRegexp                   ctermfg=186   ctermbg=NONE cterm=NONE         guifg=#E6DB74 guibg=NONE    gui=NONE
highlight rubyRegexpDelimiter          ctermfg=186   ctermbg=NONE cterm=NONE         guifg=#E6DB74 guibg=NONE    gui=NONE
highlight rubyEscape                   ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight rubyControl                  ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight rubyClassVariable            ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight rubyOperator                 ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight rubyException                ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight rubyPseudoVariable           ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight rubyRailsUserClass           ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=italic
highlight rubyRailsARAssociationMethod ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=NONE
highlight rubyRailsARMethod            ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=NONE
highlight rubyRailsRenderMethod        ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=NONE
highlight rubyRailsMethod              ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=NONE
highlight erubyDelimiter               ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight erubyComment                 ctermfg=95    ctermbg=NONE cterm=NONE         guifg=#75715E guibg=NONE    gui=NONE
highlight erubyRailsMethod             ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=NONE
highlight htmlTag                      ctermfg=148   ctermbg=NONE cterm=NONE         guifg=#A6E22E guibg=NONE    gui=NONE
highlight htmlEndTag                   ctermfg=148   ctermbg=NONE cterm=NONE         guifg=#A6E22E guibg=NONE    gui=NONE
highlight htmlTagName                  ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight htmlArg                      ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight htmlSpecialChar              ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight javaScriptFunction           ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=italic
highlight javaScriptRailsFunction      ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=NONE
highlight javaScriptBraces             ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight yamlKey                      ctermfg=197   ctermbg=NONE cterm=NONE         guifg=#F92672 guibg=NONE    gui=NONE
highlight yamlAnchor                   ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight yamlAlias                    ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
highlight yamlDocumentHeader           ctermfg=186   ctermbg=NONE cterm=NONE         guifg=#E6DB74 guibg=NONE    gui=NONE
highlight cssURL                       ctermfg=208   ctermbg=NONE cterm=NONE         guifg=#FD971F guibg=NONE    gui=italic
highlight cssFunctionName              ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=NONE
highlight cssColor                     ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight cssPseudoClassId             ctermfg=148   ctermbg=NONE cterm=NONE         guifg=#A6E22E guibg=NONE    gui=NONE
highlight cssClassName                 ctermfg=148   ctermbg=NONE cterm=NONE         guifg=#A6E22E guibg=NONE    gui=NONE
highlight cssValueLength               ctermfg=141   ctermbg=NONE cterm=NONE         guifg=#AE81FF guibg=NONE    gui=NONE
highlight cssCommonAttr                ctermfg=81    ctermbg=NONE cterm=NONE         guifg=#66D9EF guibg=NONE    gui=NONE
highlight cssBraces                    ctermfg=NONE  ctermbg=NONE cterm=NONE         guifg=NONE    guibg=NONE    gui=NONE
EOF

# Install Vim-Plug plugin manager
if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
	echo_and_eval 'curl -fL#o "$HOME/.vim/autoload/plug.vim" --create-dirs \
			https://github.com/junegunn/vim-plug/raw/master/plug.vim'
fi

# Install Vim plugins
if [[ -x "$(command -v vim)" ]]; then
	echo_and_eval 'vim -c "PlugUpgrade | PlugInstall | PlugUpdate | quitall"'
	if [[ ! -f "$HOME/.vim/plugged/markdown-preview.nvim/app/bin/markdown-preview-linux" ]]; then
		echo_and_eval 'cd "$HOME/.vim/plugged/markdown-preview.nvim/app"; ./install.sh; cd "$HOME"'
	fi
fi

# Configurations for tmux
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

echo_and_eval 'wget -N -P "$HOME/.dotfiles/" https://github.com/gpakosz//raw.tmux/master/.tmux.conf{,.local}'
ln -sf .dotfiles/.tmux.conf .
ln -sf .dotfiles/.tmux.conf.local .

sed -i 's/tmux_conf_copy_to_os_clipboard=false/tmux_conf_copy_to_os_clipboard=true/g' .dotfiles/.tmux.conf.local
sed -i 's/#set -g history-limit 10000/set -g history-limit 10000/g' .dotfiles/.tmux.conf.local
sed -i 's/#set -g mouse on/set -g mouse on/g' .dotfiles/.tmux.conf.local
if ! grep -qF 'source-file ~/.dotfiles/.tmux.conf.user' .dotfiles/.tmux.conf.local; then
	cat >>.dotfiles/.tmux.conf.local <<EOF

%if '[ -f ~/.dotfiles/.tmux.conf.user ]'
    source-file ~/.dotfiles/.tmux.conf.user
%endif
EOF
fi

# Configurations for Gitignore
backup_dotfiles .gitignore_global .dotfiles/.gitignore_global

TWO_CR=$'\r\r'
cat >.dotfiles/.gitignore_global <<EOF
##### macOS.gitignore #####
# General
.DS_Store
.AppleDouble
.LSOverride

# Icon must end with two \\r
Icon${TWO_CR}

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

# Temporary files which can be created if a process still has a handle open of a deleted file
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
Thumbs.db:encryptable
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
*.gzip
*.tgz
*.bzip
*.bzip2
*.bz2
*.xz
*.lzma
*.cab
*.xar

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
*.txz


##### Xcode.gitignore #####
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore

## User settings
xcuserdata/

## Compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
*.xcscmblueprint
*.xccheckout

## Compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

## Gcc Patch
/*.gcno


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
# since they will be recreated, and may cause churn. Uncomment if using
# auto-import.
# .idea/artifacts
# .idea/compiler.xml
# .idea/jarRepositories.xml
# .idea/modules.xml
# .idea/*.iml
# .idea/modules
# *.iml
# *.ipr

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
!.vscode/extensions.json
*.code-workspace

# Local History for Visual Studio Code
.history/


##### Vim.gitignore #####
# Swap
[._]*.s[a-v][a-z]
!*.svg  # comment out if you don't need vector files
[._]*.sw[a-p]
[._]s[a-rt-v][a-z]
[._]ss[a-gi-z]
[._]sw[a-p]

# Session
Session.vim
Sessionx.vim

# Temporary
.netrwhist
*~
# Auto-generated tag files
tags
# Persistent undo
[._]*.un~
EOF

ln -sf .dotfiles/.gitignore_global .

# Configurations for Conda
backup_dotfiles .condarc .dotfiles/.condarc

CONDA_MIRROR_SETTINGS=""
if $SET_MIRRORS; then
	CONDA_MIRROR_SETTINGS='
channels:
  - defaults
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/pro
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
channel_priority: flexible
'
fi
cat >.dotfiles/.condarc <<EOF
auto_activate_base: false
auto_update_conda: true
${CONDA_MIRROR_SETTINGS}
ssl_verify: true
show_channel_urls: false
report_errors: false

create_default_packages:
  # - anaconda
  - pip
  - jupyter
  - ipython
  - notebook
  - jupyterlab
  - ipdb
  - tqdm
  - cython
  - numpy
  - numba
  - matplotlib
  - pandas
  - seaborn
  - yapf
  - autopep8
  - pycodestyle
  - pylint

# vim: filetype=yaml tabstop=2 shiftwidth=2 expandtab
EOF

ln -sf .dotfiles/.condarc .

# Install Miniconda
if [[ ! -d "$HOME/$CONDA_DIR" ]]; then
	if $SET_MIRRORS; then
		echo_and_eval "wget -N -P \"$TMP_DIR/\" https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh"
	else
		echo_and_eval "wget -N -P \"$TMP_DIR/\" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
	fi
	echo_and_eval "bash \"$TMP_DIR/Miniconda3-latest-Linux-x86_64.sh\" -b -p \"\$HOME/$CONDA_DIR\""
	echo_and_eval "rm -f \"$TMP_DIR/Miniconda3-latest-Linux-x86_64.sh\""
fi

# Install Conda packages
export PATH="$PATH:$HOME/$CONDA_DIR/condabin"
echo_and_eval 'conda update conda --yes'
echo_and_eval 'conda install pip jupyter ipython notebook jupyterlab ipdb \
		jupyterthemes jupyter_contrib_nbextensions \
		cython numpy numba matplotlib pandas seaborn \
		tqdm yapf autopep8 pycodestyle pylint --yes'
echo_and_eval 'conda update --all --yes'
echo_and_eval 'conda clean --all --yes'
echo_and_eval "\"\$HOME/$CONDA_DIR/bin/jt\" --theme monokai --toolbar --nbname --kernellogo"
echo_and_eval "\"\$HOME/$CONDA_DIR/bin/jupyter\" contrib nbextension install --user &>/dev/null"
if $SET_MIRRORS; then
	echo_and_eval "\"\$HOME/$CONDA_DIR/bin/pip\" config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple"
fi

# Install fonts
mkdir -p "$HOME/.local/share/fonts"
FONT_DIR_LIST=('$HOME/.local/share/fonts')
if $IN_WSL; then
	FONT_DIR_LIST+=('/mnt/c/Windows/Fonts')
fi
LATEST_CASCADIA_VERSION="$(get_latest_version "microsoft/cascadia-code")"
URL_LIST=(
	"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/DejaVuSansMono.zip"
	"https://github.com/microsoft/cascadia-code/releases/latest/download/CascadiaCode-${LATEST_CASCADIA_VERSION#v}.zip"
)
echo_and_eval "wget -N -P \"$TMP_DIR/fonts\" https://github.com/XuehaiPan/OS-Setup/raw/master/Menlo.ttc"
for url in "${URL_LIST[@]}"; do
	echo_and_eval "wget -N -P \"$TMP_DIR/\" $url"
	echo_and_eval "unzip -o \"$TMP_DIR/$(basename "$url")\" -d \"$TMP_DIR/fonts\""
done
for font_dir in "${FONT_DIR_LIST[@]}"; do
	echo_and_eval "find -L \"$TMP_DIR/fonts\" -not -empty -type f -name '*.[ot]t[fc]' \\
			-printf '==> cp -f \"%p\" \"$font_dir\"\n' \\
			-exec cp -f '{}' \"$font_dir\" \\;"
done
rm -rf "$TMP_DIR"
if [[ -x "$(command -v fc-cache)" ]]; then
	echo_and_eval 'fc-cache --force'
fi
