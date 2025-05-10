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
		}' >&2
	eval "$@"
}

function have_sudo_access() {
	if [[ "${EUID:-"${UID}"}" == "0" ]]; then
		return 0
	fi

	if [[ ! -x "/usr/bin/sudo" ]]; then
		return 1
	fi

	local -a SUDO=("/usr/bin/sudo")
	if [[ -n "${SUDO_ASKPASS-}" ]]; then
		SUDO+=("-A")
	fi

	if [[ -z "${__HAVE_SUDO_ACCESS-}" ]]; then
		local RESET="\033[0m"
		local BOLD="\033[1m"
		local YELLOW="\033[33m"
		local BLUE="\033[34m"
		local WHITE="\033[37m"
		echo -e "${BOLD}${BLUE}==> ${WHITE}Checking sudo access (press ${YELLOW}Control+C${WHITE} to run as normal user).${RESET}" >&2
		exec_cmd "${SUDO[*]} -v && ${SUDO[*]} -l mkdir &>/dev/null"
		__HAVE_SUDO_ACCESS="$?"
	fi

	return "${__HAVE_SUDO_ACCESS}"
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
	export ZSH="${ZSH:-"${HOME}/.oh-my-zsh"}"
	export ZSH_CUSTOM="${ZSH_CUSTOM:-"${ZSH}/custom"}"
	export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-"${ZSH}/cache"}"

	# Upgrade oh my zsh
	rm -f "${ZSH_CACHE_DIR}/.zsh-update" 2>/dev/null
	zsh "${ZSH}/tools/check_for_upgrade.sh" 2>/dev/null
	exec_cmd 'zsh "${ZSH}/tools/upgrade.sh"'
	exec_cmd 'git -C "${ZSH}" fetch --prune'
	exec_cmd 'git -C "${ZSH}" gc --prune=all'

	# Upgrade themes and plugins
	while read -r repo; do
		exec_cmd "git -C \"\${ZSH_CUSTOM}/${repo}\" pull --prune --ff-only"
		exec_cmd "git -C \"\${ZSH_CUSTOM}/${repo}\" gc --prune=all"
	done < <(
		cd "${ZSH_CUSTOM}" &&
			find -L . -mindepth 3 -maxdepth 3 -not -empty -type d -name '.git' -prune -exec dirname '{}' ';' |
			cut -c3-
	)

	# Remove old zcompdump file
	rm -f "${ZSH_COMPDUMP:-"${ZDOTDIR:-"${HOME}"}"/.zcompdump}" &>/dev/null
}

function upgrade_fzf() {
	exec_cmd 'git -C "${HOME}/.fzf" pull --prune --ff-only'
	exec_cmd 'git -C "${HOME}/.fzf" gc --prune=all'
	exec_cmd '"${HOME}/.fzf/install" --key-bindings --completion --no-update-rc'
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

	# Upgrade Conda and Mamba
	exec_cmd 'conda update conda mamba --name=base --yes'

	# Upgrade Conda packages in each environment
	while read -r env; do
		cmds="conda update --all --yes"
		if conda list --full-name anaconda --name="${env}" | grep -q '^anaconda[^-]'; then
			cmds="${cmds}; conda update anaconda --yes"
		fi
		exec_cmd "conda activate ${env}; ${cmds}; conda deactivate"
	done < <(conda info --envs | awk 'NF > 0 && $0 !~ /^#.*/ { print $1 }')

	# Clean up Conda cache
	exec_cmd 'conda clean --all --yes'
}

function foreach_conda_env_do() {
	local env

	# Execute in each Conda environment
	while read -r env; do
		exec_cmd "conda activate ${env}; ${*}; conda deactivate"
	done < <(conda info --envs | awk 'NF > 0 && $0 !~ /^#.*/ { print $1 }')
}

function upgrade_packages() {
	unset __HAVE_SUDO_ACCESS

	upgrade_homebrew
	upgrade_ohmyzsh
	upgrade_fzf
	upgrade_vim
	upgrade_gems
	# upgrade_cpan
	upgrade_texlive
	# upgrade_conda

	if [[ -n "${ZSH_VERSION}" ]]; then
		rm -f "${ZSH_COMPDUMP:-"${ZDOTDIR:-"${HOME}"}"/.zcompdump}" &>/dev/null
		if [[ -f "${ZDOTDIR:-"${HOME}"}/.zshrc" ]]; then
			source "${ZDOTDIR:-"${HOME}"}/.zshrc"
		fi
	elif [[ -n "${BASH_VERSION}" ]]; then
		if [[ -f "${HOME}/.bash_profile" ]]; then
			source "${HOME}/.bash_profile"
		elif [[ -f "${HOME}/.profile" ]]; then
			source "${HOME}/.profile"
		fi
	fi
}

function set_proxy() {
	local proxy_host="${1:-"127.0.0.1"}"
	local http_port="${2:-"7890"}"
	local https_port="${3:-"7890"}"
	local ftp_port="${4:-"7890"}"
	local socks_port="${5:-"7891"}"

	export http_proxy="http://${proxy_host}:${http_port}"
	export https_proxy="http://${proxy_host}:${https_port}"
	export ftp_proxy="http://${proxy_host}:${ftp_port}"
	export all_proxy="socks5://${proxy_host}:${socks_port}"
	export HTTP_PROXY="${http_proxy}"
	export HTTPS_PROXY="${https_proxy}"
	export FTP_PROXY="${ftp_proxy}"
	export ALL_PROXY="${all_proxy}"
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
		pids=$(nvidia-smi --id="${index}" --query-compute-apps=pid --format=csv,noheader | xargs echo -n)
		if [[ -n "${pids}" ]] && (ps -o user -p "${pids}" | tail -n +2 | grep -qvF "${USER}") &&
			((memused >= 3072 || memfree <= 6144 || utilization >= 20)); then
			continue
		fi
		available="${available:+"${available}",}${index}"
		((maxcount -= 1))
	done < <(
		nvidia-smi --query-gpu=index,memory.free,memory.used,utilization.gpu --format=csv,noheader,nounits |
			sort -t ',' -k2nr -k4n -k3n -k1nr | tr -d ','
	)

	echo "${available}"
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
		CMD="transmission-remote --torrent ${TORRENT} --reannounce"
		eval "${CMD}" 1>/dev/null
		for ((r = INTERVAL - 1; r >= 0; --r)); do
			echo -ne "${CMD} (${t}/${TIMES}, next reannounce in ${r}s)\033[K\r"
			sleep 1
		done
	done

	echo -ne "\033[K\033[?25h"
}

function pull_projects() {
	local base_dirs base_dir proj_dir
	local head_hash old_head_hash branch remote remote_hash push_remote push_remote_hash

	# Project directories
	if [[ "$#" -gt 0 ]]; then
		base_dirs=("$@")
	else
		base_dirs=("${HOME}/Projects")
	fi

	# Fetch and pull
	for base_dir in "${base_dirs[@]}"; do
		while read -r proj_dir; do
			branch="$(git -C "${proj_dir}" branch --show-current)"
			remote="$(git -C "${proj_dir}" config branch."${branch}".remote)"
			if [[ -z "${branch}" || -z "${remote}" ]]; then
				continue
			fi
			exec_cmd "git -C \"${proj_dir/#${HOME}/\${HOME\}}\" fetch --all --prune"
			old_head_hash="$(git -C "${proj_dir}" rev-parse "${branch}")"
			head_hash="$(git -C "${proj_dir}" rev-parse "${remote}/${branch}")"
			if [[ "${head_hash}" != "${old_head_hash}" ]]; then
				exec_cmd "git -C \"${proj_dir/#${HOME}/\${HOME\}}\" pull ${remote} ${branch} --ff-only"
				if (("$(git -C "${project_dir}" rev-list --count --all)" <= 10000 )); then
					exec_cmd "git -C \"${proj_dir/#${HOME}/\${HOME\}}\" gc --aggressive"
				fi
			fi
			push_remote="$(git -C "${proj_dir}" config branch."${branch}".pushremote)"
			if [[ -n "${push_remote}" ]]; then
				push_remote_hash="$(git -C "${proj_dir}" rev-parse "${push_remote}/${branch}")"
				if [[ "${head_hash}" != "${push_remote_hash}" ]]; then
					exec_cmd "git -C \"${proj_dir/#${HOME}/\${HOME\}}\" push ${push_remote} ${branch} || true"
				fi
			fi
		done < <(
			find -L "${base_dir}" -maxdepth 5 -not -empty -type d -name '.git' -prune -exec dirname '{}' ';'
		)
	done
}
