#!/usr/bin/env bash

function echo_and_eval() {
	local CMD="$*"
	printf "%s" "$CMD" | awk \
		'BEGIN {
			UnderlineBoldGreen = "\033[4;1;32m";
			BoldRed = "\033[1;31m";
			BoldGreen = "\033[1;32m";
			BoldYellow = "\033[1;33m";
			BoldWhite = "\033[1;37m";
			Reset = "\033[0m";
			idx = 0;
			in_string = 0;
			printf("%s$%s", BoldWhite, Reset);
		}
		{
			for (i = 1; i <= NF; ++i) {
				Style = BoldWhite;
				if (!in_string) {
					if ($i ~ /^-/) {
						Style = BoldYellow;
					} else if ($i == "sudo") {
						Style = UnderlineBoldGreen;
					} else if ($i ~ /^[12&]?>>?/) {
						Style = BoldRed;
					} else {
						++idx;
						if ($i ~ /^"/) {
							in_string = 1;
						}
						else if (idx == 1) {
							Style = BoldGreen;
						}
					}
				}
				if (in_string && $i ~ /";?$/) {
					in_string = 0;
				}
				if ($i ~ /;$/ || $i == "|" || $i == "||" || $i == "&&") {
					if (!in_string) {
						idx = 0;
						if ($i !~ /;$/) {
							Style = BoldRed;
						}
					}
				}
				if ($i ~ /;$/) {
					printf(" %s%s%s;%s", Style, substr($i, 1, length($i) - 1), (in_string ? BoldWhite : BoldRed), Reset);
				} else {
					printf(" %s%s%s", Style, $i, Reset);
				}
				if ($i == "\\") {
					printf("\n\t");
				}
			}
		}
		END {
			printf("\n");
		}'
	eval "$CMD"
}

function upgrade_homebrew() {
	# Upgrade Homebrew
	echo_and_eval 'brew update --verbose'

	# Upgrade Homebrew Formulas
	echo_and_eval 'brew outdated'
	echo_and_eval 'brew upgrade'

	# Upgrade Homebrew Casks
	echo_and_eval 'brew cask outdated'
	echo_and_eval 'brew cask upgrade'

	# Clean Homebrew Cache
	echo_and_eval 'brew cleanup'
}

function upgrade_ohmyzsh() {
	# Set oh-my-zsh installation path
	export ZSH="${ZSH:-"$HOME/.oh-my-zsh"}"
	export ZSH_CUSTOM="${ZSH_CUSTOM:-"$ZSH/custom"}"

	# Upgrade oh my zsh
	echo_and_eval 'zsh "$ZSH/tools/upgrade.sh"'

	# Upgrade themes and plugins
	local REPOS=($(
		cd "$ZSH_CUSTOM"
		find . -depth 3 -not -empty -type d -name '.git' \
			| sed -e 's#^\.\/\(.*\)\/\.git$#\1#'
	))
	for repo in "${REPOS[@]}"; do
		echo_and_eval "git -C \"\$ZSH_CUSTOM/$repo\" pull"
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

function upgrade_cpan() {
	echo_and_eval 'cpan -u'
}

function upgrade_texlive() {
	echo_and_eval 'sudo tlmgr update --self --all'
}

function upgrade_conda() {
	# Upgrade Conda
	echo_and_eval 'conda update conda --name base --yes'

	# Upgrade Conda Packages
	echo_and_eval 'conda update --all --name base --yes'

	# Upgrade Conda Packages in Each Environment
	local ENVS=(base $(
		cd "$(conda info --base)/envs"
		find . -depth 1 -not -empty \( -type d -or -type l \) \
			| sed -e 's#^\.\/\(.*\)$#\1#'
	))
	for env in "${ENVS[@]}"; do
		echo_and_eval "conda update --all --name $env --yes"
		if conda list --name "$env" | grep -q '^anaconda[^-]'; then
			echo_and_eval "conda update anaconda --name $env --yes"
		fi
	done

	# Clean Conda Cache
	echo_and_eval 'conda clean --all --yes'
}

function set_proxy() {
	export https_proxy="http://127.0.0.1:7890"
	export http_proxy="http://127.0.0.1:7890"
	export ftp_proxy="http://127.0.0.1:7890"
	export all_proxy="socks5://127.0.0.1:7891"
	export HTTPS_PROXY="http://127.0.0.1:7890"
	export HTTP_PROXY="http://127.0.0.1:7890"
	export FTP_PROXY="http://127.0.0.1:7890"
	export ALL_PROXY="socks5://127.0.0.1:7891"
}

function reset_proxy() {
	export https_proxy=""
	export http_proxy=""
	export ftp_proxy=""
	export all_proxy=""
	export HTTPS_PROXY=""
	export HTTP_PROXY=""
	export FTP_PROXY=""
	export ALL_PROXY=""
}

function pull_projects() {
	# Project Directories
	local BASE_DIRS=("$HOME/VSCodeProjects" "$HOME/PycharmProjects" "$HOME/ClionProjects" "$HOME/IdeaProjects")

	# Fetch and Pull Git
	for BASE_DIR in "${BASE_DIRS[@]}"; do
		local PROJ_DIRS=($(
			find "$BASE_DIR" -not -empty -type d -name '.git' \
				| sed -e 's#^\(.*\)\/\.git$#\1#'
		))
		for PROJ_DIR in "${PROJ_DIRS[@]}"; do
			if [[ -n "$(git -C "$PROJ_DIR" remote)" ]]; then
				echo_and_eval "git -C \"${PROJ_DIR/#$HOME/\$HOME}\" fetch --all --prune"
				echo_and_eval "git -C \"${PROJ_DIR/#$HOME/\$HOME}\" pull"
			fi
		done
	done
}
