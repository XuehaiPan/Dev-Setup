#!/usr/bin/env bash

# Options
export SET_MIRRORS="${SET_MIRRORS:-true}"

# Colors
BOLDRED="\033[1;31m"
BOLDGREEN="\033[1;32m"
BOLDYELLOW="\033[1;33m"
BOLDWHITE="\033[1;37m"
RESET="\033[0m"

# Start logging
LOG_FILE="$PWD/os-setup.log"
if [[ -f "$LOG_FILE" ]]; then
	mv -f "$LOG_FILE" "${LOG_FILE}.old"
fi
exec 2> >(tee -a "$LOG_FILE" >&2)
echo -e "${BOLDWHITE}The script output will be logged to file ${BOLDYELLOW}\"$LOG_FILE\"${BOLDWHITE}.${RESET}" >&2

# Get system information
OS_NAME=""
if [[ "$(uname -s)" == "Darwin" ]]; then
	OS_NAME="macOS"
elif [[ "$(uname -s)" == "Linux" ]]; then
	if grep -qiE 'ID.*ubuntu' /etc/*-release; then
		OS_NAME="Ubuntu"
	elif grep -qiE 'ID.*manjaro' /etc/*-release; then
		OS_NAME="Manjaro"
	fi
fi

if [[ -z "$OS_NAME" ]]; then
	echo -e "${BOLDRED}The operating system is not supported yet. ${BOLDYELLOW}Only macOS, Ubuntu Linux, and Manjaro Linux are supported.${RESET}" >&2
	exit 1
fi

echo -e "${BOLDWHITE}Operating System: ${BOLDGREEN}${OS_NAME}${RESET}"

# Run script if it exists
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -x "$SCRIPT_DIR/setup_${OS_NAME}.sh" && "$(basename "$0")" == "setup.sh" ]]; then
	if [[ -d "$SCRIPT_DIR/.git" || "$(basename "$SCRIPT_DIR")" == "OS-Setup-master" ]]; then
		echo -e "${BOLDWHITE}Run existing script ${BOLDGREEN}\"$SCRIPT_DIR/setup_${OS_NAME}.sh\"${BOLDWHITE}.${RESET}" >&2
		bash "$SCRIPT_DIR/setup_${OS_NAME}.sh"
		exit
	fi
fi

# Download and run
if [[ -x "$(command -v wget)" ]]; then
	echo -e "${BOLDWHITE}Download and run script via ${BOLDGREEN}wget${BOLDWHITE}.${RESET}" >&2
	bash -c "$(wget --progress=bar:force:noscroll -O - https://raw.githubusercontent.com/XuehaiPan/OS-Setup/master/setup_${OS_NAME}.sh)"
elif [[ -x "$(command -v curl)" ]]; then
	echo -e "${BOLDWHITE}Download and run script via ${BOLDGREEN}curl${BOLDWHITE}.${RESET}" >&2
	bash -c "$(curl -fL# https://raw.githubusercontent.com/XuehaiPan/OS-Setup/master/setup_${OS_NAME}.sh)"
elif [[ -x "$(command -v git)" ]]; then
	echo -e "${BOLDWHITE}Download and run script via ${BOLDGREEN}git${BOLDWHITE}.${RESET}" >&2
	git clone --depth=1 https://github.com/XuehaiPan/OS-Setup.git 2>&1
	bash "OS-Setup/setup_${OS_NAME}.sh"
else
	echo -e "${BOLDWHITE}Please download the script from ${BOLDYELLOW}https://github.com/XuehaiPan/OS-Setup${BOLDWHITE} manually.${RESET}" >&2
fi
