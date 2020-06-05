#!/usr/bin/env bash

function echo_and_eval() {
	printf "%s" "$@" | awk \
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
					} else if ($i == "sudo" && idx == 0) {
						Style = UnderlineBoldGreen;
					} else if ($i ~ /^[12&]?>>?/) {
						Style = BoldRed;
					} else {
						++idx;
						if ($i ~ /^"/) {
							in_string = 1;
						}
						if (idx == 1) {
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
	eval "$@"
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
	echo_and_eval 'brew cleanup -s --prune 7'
}

function upgrade_ohmyzsh() {
	local REPOS repo

	# Set oh-my-zsh installation path
	export ZSH="${ZSH:-"$HOME/.oh-my-zsh"}"
	export ZSH_CUSTOM="${ZSH_CUSTOM:-"$ZSH/custom"}"

	# Upgrade oh my zsh
	echo_and_eval 'zsh "$ZSH/tools/upgrade.sh"'

	# Upgrade themes and plugins
	REPOS=($(
		cd "$ZSH_CUSTOM"
		find -L . -mindepth 3 -maxdepth 3 -not -empty -type d -name '.git' |
			sed -e 's#^\.\/\(.*\)\/\.git$#\1#'
	))
	for repo in "${REPOS[@]}"; do
		echo_and_eval "git -C \"\$ZSH_CUSTOM/$repo\" pull --ff-only"
	done
}

function upgrade_fzf() {
	echo_and_eval 'git -C "$HOME/.fzf" pull --ff-only'
	echo_and_eval '"$HOME/.fzf/install" --key-bindings --completion --no-update-rc'
}

function upgrade_vim() {
	echo_and_eval 'vim -c "PlugUpgrade | PlugUpdate | quitall"'
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
	local ENVS env

	# Upgrade Conda
	echo_and_eval 'conda update conda --name base --yes'

	# Upgrade Conda Packages in Each Environment
	ENVS=(base $(
		cd "$(conda info --base)/envs"
		find -L . -mindepth 1 -maxdepth 1 -not -empty \( -type d -or -type l \) |
			sed -e 's#^\.\/\(.*\)$#\1#'
	))
	for env in "${ENVS[@]}"; do
		echo_and_eval "conda update --all --name $env --yes"
		if conda list --full-name anaconda --name "$env" | grep -q '^anaconda[^-]'; then
			echo_and_eval "conda update anaconda --name $env --yes"
		fi
	done

	# Clean Conda Cache
	echo_and_eval 'conda clean --all --yes'
}

function set_proxy() {
	local PROXY_HOST="${1:-"127.0.0.1"}"
	local HTTP_PORT="${2:-"7890"}"
	local HTTPS_PORT="${3:-"7890"}"
	local FTP_PORT="${4:-"7890"}"
	local SOCKS_PORT="${5:-"7891"}"

	export http_proxy="http://${PROXY_HOST}:${HTTP_PORT}"
	export https_proxy="http://${PROXY_HOST}:${HTTPS_PORT}"
	export ftp_proxy="http://${PROXY_HOST}:${FTP_PORT}"
	export all_proxy="socks5://${PROXY_HOST}:${SOCKS_PORT}"
	export HTTP_PROXY="$http_proxy"
	export HTTPS_PROXY="$https_proxy"
	export FTP_PROXY="$ftp_proxy"
	export ALL_PROXY="$all_proxy"
}

function reset_proxy() {
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
	local TIMES="${1:-60}"
	local INTERVAL="${2:-60}"
	local TORRENT CMD t r

	echo -ne "\033[?25l"

	for ((t = 0; t <= TIMES; ++t)); do
		if [[ $((t % 5)) != 0 ]]; then
			TORRENT="active"
		else
			TORRENT="all"
		fi
		CMD="transmission-remote --torrent $TORRENT --reannounce"
		eval "$CMD" 1>/dev/null
		for ((r = INTERVAL - 1; r >= 0; --r)); do
			echo -ne "$CMD ($t/$TIMES, next reannounce in ${r}s)\033[K\r"
			sleep 1
		done
	done

	echo -ne "\033[K\033[?25h"
}

function pull_projects() {
	local BASE_DIRS BASE_DIR PROJ_DIRS PROJ_DIR

	# Project Directories
	BASE_DIRS=("$HOME/VSCodeProjects" "$HOME/PycharmProjects" "$HOME/ClionProjects" "$HOME/IdeaProjects")

	# Fetch and Pull Git
	for BASE_DIR in "${BASE_DIRS[@]}"; do
		PROJ_DIRS=($(
			find -L "$BASE_DIR" -not -empty -type d -name '.git' |
				sed -e 's#^\(.*\)\/\.git$#\1#'
		))
		for PROJ_DIR in "${PROJ_DIRS[@]}"; do
			if [[ -n "$(git -C "$PROJ_DIR" remote)" ]]; then
				echo_and_eval "git -C \"${PROJ_DIR/#$HOME/\$HOME}\" fetch --all --prune"
				echo_and_eval "git -C \"${PROJ_DIR/#$HOME/\$HOME}\" pull --ff-only"
			fi
		done
	done
}
