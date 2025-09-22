#!/usr/bin/env bash

# Colors
RESET="\033[0m"
UNDERLINE="\033[4m"
UNDERLINEOFF="\033[24m"
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
WHITE="\033[37m"

if [[ -z "${BASH_VERSION}" ]]; then
	echo -e "${BOLD}${RED}ERROR: ${WHITE}Please run this script using ${GREEN}bash${WHITE}, not ${YELLOW}sh or other shells${WHITE}.${RESET}" >&2
	exit 1
fi

# Get system information
OS_NAME=""
if [[ "$(uname -s)" == "Darwin" ]]; then
	OS_NAME="macOS"
	PACKAGE_MANAGER="Homebrew"
elif [[ "$(uname -s)" == "Linux" ]]; then
	if grep -qiE 'ID.*ubuntu' /etc/*-release; then
		OS_NAME="Ubuntu"
		PACKAGE_MANAGER="APT, Homebrew"
	elif grep -qiE 'ID.*debian' /etc/*-release; then
		OS_NAME="Debian"
		PACKAGE_MANAGER="APT, Homebrew"
	elif grep -qiE 'ID.*manjaro' /etc/*-release; then
		OS_NAME="Manjaro"
		PACKAGE_MANAGER="Pacman, Homebrew"
	fi
fi

if [[ -z "${OS_NAME}" ]]; then
	echo -e "${BOLD}${RED}The operating system is not supported yet. ${YELLOW}Only macOS, Debian/Ubuntu Linux, and Manjaro Linux are supported.${RESET}" >&2
	exit 1
fi

echo -e "${BOLD}${WHITE}Operating System: ${GREEN}${OS_NAME}${RESET}" >&2

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IS_LOCAL_SCRIPT=''
if [[ -x "${SCRIPT_DIR}/setup_${OS_NAME}.sh" && "$(basename "$0")" == "setup.sh" ]]; then
	IS_LOCAL_SCRIPT=true
fi

function print_help() {
	(
		echo -e "${BOLD}${WHITE}Usage: ${GREEN}/bin/bash setup.sh [options]${RESET}"
		echo
		echo -e "${BOLD}${WHITE}Options:${RESET}"
		echo -e "  ${GREEN}--set-mirrors [yes|no]${RESET}      Set or not set the source of package managers to the open source mirrors at TUNA (@China)."
		echo -e "  ${GREEN}--no-set-mirrors${RESET}            Do not set the source of package managers to the open source mirrors at TUNA (@China)."
		echo
		echo -e "  ${GREEN}--force-per-user-homebrew${RESET}   Force to install Homebrew in per-user mode even if running as sudoers (Linux only)."
		echo
		echo -e "  ${GREEN}--help, -h${RESET}                  Show this help message and exit."
		echo
		echo -e "${BOLD}${WHITE}If no option is provided for setting mirrors, the script will prompt for confirmation.${RESET}"
	) >&2
}

while (("$#" > 0)); do
	option="$1"
	case "${option}" in
	--set-mirrors)
		shift
		if [[ -z "${1:-}" ]] || [[ "${1:-}" == --* ]]; then
			SET_MIRRORS=true
		else
			SET_MIRRORS="${1:-}"
			shift
		fi
		;;
	--no-set-mirrors)
		SET_MIRRORS=false
		shift
		;;
	--set-mirrors=*)
		SET_MIRRORS="${1#*=}"
		shift
		;;
	--force-per-user-homebrew)
		export FORCE_PER_USER_HOMEBREW=true
		shift
		;;
	--help | -h)
		echo
		print_help
		exit 0
		;;
	*)
		echo -e "${BOLD}${RED}Warning: Unknown option: '${option}'.${RESET}" >&2
		shift
		;;
	esac
done

# Options
if [[ "${SET_MIRRORS}" =~ (1|yes|Yes|YES|true|True|TRUE|on|On|ON) ]]; then
	SET_MIRRORS=true
elif [[ "${SET_MIRRORS}" =~ (0|no|No|NO|false|False|FALSE|off|Off|OFF) ]]; then
	SET_MIRRORS=false
else
	if [[ -n "${SET_MIRRORS}" ]]; then
		echo -e "${BOLD}${YELLOW}Warning: Unknown value for SET_MIRRORS: '${SET_MIRRORS}'.${RESET}" >&2
	fi
	unset SET_MIRRORS
	if [[ -t 0 ]] && [[ -t 1 ]]; then
		while true; do
			read -n 1 -p "$(
				echo -e "${BOLD}${WHITE}Do you wish to set the source of package managers ${GREEN}(${PACKAGE_MANAGER}, CPAN, Gem, Conda, and Pip)${WHITE}"
				echo -e "to the open source mirrors at ${YELLOW}TUNA (@China) (${UNDERLINE}https://mirrors.tuna.tsinghua.edu.cn${UNDERLINEOFF})${WHITE} [y/N]: ${RESET}"
			)" answer
			if [[ -n "${answer}" ]]; then
				echo
			else
				answer="n"
			fi
			if [[ "${answer}" == [Yy] ]]; then
				SET_MIRRORS=true
				break
			elif [[ "${answer}" == [Nn] ]]; then
				SET_MIRRORS=false
				break
			fi
		done
	fi
fi
export SET_MIRRORS

# Start logging
export DEV_SETUP_BACKUP_DIR="${HOME}/.dotfiles/backups/$(date +"%Y-%m-%d-%T")"
mkdir -p "${DEV_SETUP_BACKUP_DIR}/.dotfiles"
chmod 755 "${HOME}/.dotfiles"
LOG_FILE="${DEV_SETUP_BACKUP_DIR}/dev-setup.log"
exec 2> >(tee -a "${LOG_FILE}" >&2)
echo -e "${BOLD}${WHITE}The script output will be logged to file ${YELLOW}\"${LOG_FILE}\"${WHITE}.${RESET}" >&2

# Run script if it exists
if [[ -n "${IS_LOCAL_SCRIPT}" ]]; then
	echo -e "${BOLD}${WHITE}Run existing script ${GREEN}\"${SCRIPT_DIR}/setup_${OS_NAME}.sh\"${WHITE}.${RESET}" >&2
	echo
	exec /bin/bash "${SCRIPT_DIR}/setup_${OS_NAME}.sh"
fi

# Download and run
if [[ -x "$(command -v wget)" ]]; then
	echo -e "${BOLD}${WHITE}Download and run script via ${GREEN}wget${WHITE}.${RESET}" >&2
	echo
	exec /bin/bash -c "$(wget --progress=bar:force:noscroll -O - "https://github.com/XuehaiPan/Dev-Setup/raw/HEAD/setup_${OS_NAME}.sh")"
elif [[ -x "$(command -v curl)" ]]; then
	echo -e "${BOLD}${WHITE}Download and run script via ${GREEN}curl${WHITE}.${RESET}" >&2
	echo
	exec /bin/bash -c "$(curl -fL# "https://github.com/XuehaiPan/Dev-Setup/raw/HEAD/setup_${OS_NAME}.sh")"
elif [[ -x "$(command -v git)" ]]; then
	echo -e "${BOLD}${WHITE}Download and run script via ${GREEN}git${WHITE}.${RESET}" >&2
	echo
	git clone --depth=1 https://github.com/XuehaiPan/Dev-Setup.git 2>&1
	exec /bin/bash "Dev-Setup/setup_${OS_NAME}.sh"
else
	echo -e "${BOLD}${WHITE}Please download the script from ${YELLOW}https://github.com/XuehaiPan/Dev-Setup${WHITE} manually.${RESET}" >&2
fi
