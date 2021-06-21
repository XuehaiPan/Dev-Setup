#!/usr/bin/env bash

function exec_cmd() {
	printf "%s" "$@" | awk \
		'BEGIN {
			RESET = "\033[0m";
			BOLD = "\033[1m";
			UNDERLINE = "\033[4m";
			UNDERLINEOFF = "\033[24m";
			RED = "\033[31m";
			GREEN = "\033[32m";
			YELLOW = "\033[33m";
			WHITE = "\033[37m";
			GRAY = "\033[90m";
			IDENTIFIER = "[_a-zA-Z][_a-zA-Z0-9]*";
			idx = 0;
			in_string = 0;
			double_quoted = 1;
			printf("%s$", BOLD WHITE);
		}
		{
			for (i = 1; i <= NF; ++i) {
				style = WHITE;
				post_style = WHITE;
				if (!in_string) {
					if ($i ~ /^-/)
						style = YELLOW;
					else if ($i == "sudo" && idx == 0) {
						style = UNDERLINE GREEN;
						post_style = UNDERLINEOFF WHITE;
					}
					else if ($i ~ "^" IDENTIFIER "=" && idx == 0) {
						style = GRAY;
						'"if (\$i ~ \"^\" IDENTIFIER \"=[\\\"']\") {"'
							in_string = 1;
							double_quoted = ($i ~ "^" IDENTIFIER "=\"");
						}
					}
					else if ($i ~ /^[12&]?>>?/ || $i == "\\")
						style = RED;
					else {
						++idx;
						'"if (\$i ~ /^[\"']/) {"'
							in_string = 1;
							double_quoted = ($i ~ /^"/);
						}
						if (idx == 1)
							style = GREEN;
					}
				}
				if (in_string) {
					if (style == WHITE)
						style = "";
					post_style = "";
					'"if ((double_quoted && \$i ~ /\";?\$/ && \$i !~ /\\\\\";?\$/) || (!double_quoted && \$i ~ /';?\$/))"'
						in_string = 0;
				}
				if (($i ~ /;$/ && $i !~ /\\;$/) || $i == "|" || $i == "||" || $i == "&&") {
					if (!in_string) {
						idx = 0;
						if ($i !~ /;$/)
							style = RED;
					}
				}
				if ($i ~ /;$/ && $i !~ /\\;$/)
					printf(" %s%s%s;%s", style, substr($i, 1, length($i) - 1), (in_string ? WHITE : RED), post_style);
				else
					printf(" %s%s%s", style, $i, post_style);
				if ($i == "\\")
					printf("\n\t");
			}
		}
		END {
			printf("%s\n", RESET);
		}'
	eval "$@"
}

function upgrade_homebrew() {
	# Upgrade Homebrew
	exec_cmd 'brew update --verbose'
	exec_cmd 'brew outdated'

	# Upgrade Homebrew formulae and casks
	exec_cmd 'brew upgrade'

	# Uninstall formulae that no longer needed
	exec_cmd 'brew autoremove --verbose'

	# Clean up Homebrew cache
	exec_cmd 'brew cleanup -s --prune 7'
}

function upgrade_ohmyzsh() {
	local repo

	# Set oh-my-zsh installation path
	export ZSH="${ZSH:-"$HOME/.oh-my-zsh"}"
	export ZSH_CUSTOM="${ZSH_CUSTOM:-"$ZSH/custom"}"
	export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-"$ZSH/cache"}"

	# Upgrade oh my zsh
	rm -f "$ZSH_CACHE_DIR/.zsh-update" 2>/dev/null
	zsh "$ZSH/tools/check_for_upgrade.sh" 2>/dev/null
	exec_cmd 'zsh "$ZSH/tools/upgrade.sh"'
	exec_cmd 'git -C "$ZSH" fetch --prune'
	exec_cmd 'git -C "$ZSH" gc --prune=all'

	# Upgrade themes and plugins
	while read -r repo; do
		exec_cmd "git -C \"\$ZSH_CUSTOM/$repo\" pull --prune --ff-only"
		exec_cmd "git -C \"\$ZSH_CUSTOM/$repo\" gc --prune=all"
	done < <(
		cd "$ZSH_CUSTOM" &&
			find -L . -mindepth 3 -maxdepth 3 -not -empty -type d -name '.git' -prune -exec dirname {} \; |
			cut -b3-
	)

	# Remove old zcompdump file
	rm -f "${ZSH_COMPDUMP:-"${ZDOTDIR:-"$HOME"}"/.zcompdump}" &>/dev/null
}

function upgrade_fzf() {
	exec_cmd 'git -C "$HOME/.fzf" pull --prune --ff-only'
	exec_cmd 'git -C "$HOME/.fzf" gc --prune=all'
	exec_cmd '"$HOME/.fzf/install" --key-bindings --completion --no-update-rc'
}

function upgrade_vim() {
	exec_cmd 'vim -c "PlugUpgrade | PlugUpdate | sleep 5 | quitall"'
}

function upgrade_gems() {
	exec_cmd 'gem update --system'
	exec_cmd 'gem update'
	exec_cmd 'gem cleanup'
}

function upgrade_cpan() {
	exec_cmd 'cpan -u'
}

function upgrade_texlive() {
	exec_cmd 'sudo tlmgr update --self --all'
}

function upgrade_conda() {
	local env cmds

	# Upgrade Conda
	exec_cmd 'conda update conda --name base --yes'

	# Upgrade Conda packages in each environment
	while read -r env; do
		cmds="conda update --all --yes"
		if conda list --full-name anaconda --name "$env" | grep -q '^anaconda[^-]'; then
			cmds="$cmds; conda update anaconda --yes"
		fi
		exec_cmd "conda activate $env; $cmds; conda deactivate"
	done < <(conda info --envs | awk 'NF > 0 && $0 !~ /^#.*/ { print $1 }')

	# Clean up Conda cache
	exec_cmd 'conda clean --all --yes'
}

function foreach_conda_env_do() {
	local env

	# Execute in each Conda environment
	while read -r env; do
		exec_cmd "conda activate $env; ${*}; conda deactivate"
	done < <(conda info --envs | awk 'NF > 0 && $0 !~ /^#.*/ { print $1 }')
}

function upgrade_packages() {
	upgrade_homebrew
	upgrade_ohmyzsh
	upgrade_fzf
	upgrade_vim
	upgrade_gems
	# upgrade_cpan
	upgrade_texlive
	# upgrade_conda

	if [[ -n "$ZSH_VERSION" ]]; then
		rm -f "${ZSH_COMPDUMP:-"${ZDOTDIR:-"$HOME"}"/.zcompdump}" &>/dev/null
		if [[ -f "${ZDOTDIR:-"$HOME"}/.zshrc" ]]; then
			source "${ZDOTDIR:-"$HOME"}/.zshrc"
		fi
	elif [[ -n "$BASH_VERSION" ]]; then
		if [[ -f "$HOME/.bash_profile" ]]; then
			source "$HOME/.bash_profile"
		fi
	fi
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

function available_cuda_devices() {
	local maxcount="${1:-4}"
	local available="" index memfree memused utilization pids

	while read -r index memfree memused utilization; do
		if ! ((maxcount > 0)); then
			break
		fi
		pids=$(nvidia-smi --id="$index" --query-compute-apps=pid --format=csv,noheader | xargs echo -n)
		if [[ -n "$pids" ]] && (ps -o user -p $pids | tail -n +2 | grep -qvF "$USER") &&
			((memused >= 3072 || memfree <= 6144 || utilization >= 20)); then
			continue
		fi
		available="${available:+$available,}$index"
		((maxcount -= 1))
	done < <(
		nvidia-smi --query-gpu=index,memory.free,memory.used,utilization.gpu --format=csv,noheader,nounits |
			sort -t ',' -k2nr -k4n -k3n -k1nr | tr -d ','
	)

	echo "$available"
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
	local BASE_DIRS BASE_DIR PROJ_DIR HEAD_HASH

	# Project directories
	if [ "$#" -gt 0 ]; then
		BASE_DIRS=("$@")
	else
		BASE_DIRS=("$HOME/VSCodeProjects" "$HOME/PycharmProjects" "$HOME/ClionProjects" "$HOME/IdeaProjects")
	fi

	# Fetch and pull
	for BASE_DIR in "${BASE_DIRS[@]}"; do
		while read -r PROJ_DIR; do
			if [[ -n "$(git -C "$PROJ_DIR" remote)" ]]; then
				exec_cmd "git -C \"${PROJ_DIR/#$HOME/\$HOME}\" fetch --all --prune"
				HEAD_HASH="$(git -C "$PROJ_DIR" rev-parse HEAD)"
				exec_cmd "git -C \"${PROJ_DIR/#$HOME/\$HOME}\" pull --ff-only"
				if [[ "$HEAD_HASH" != "$(git -C "$PROJ_DIR" rev-parse HEAD)" ]]; then
					exec_cmd "git -C \"${PROJ_DIR/#$HOME/\$HOME}\" gc --aggressive"
				fi
			fi
		done < <(
			find -L "$BASE_DIR" -maxdepth 5 -not -empty -type d -name '.git' -prune -exec dirname {} \;
		)
	done
}
