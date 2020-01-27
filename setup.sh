#!/usr/bin/env bash

# Colors
BOLDRED="\033[1;31m"
BOLDGREEN="\033[1;32m"
BOLDYELLOW="\033[1;33m"
BOLDWHITE="\033[1;37m"
RESET="\033[0m"

# Get system infomation
OS_NAME=""
if [[ "$(uname -s)" == "Darwin" ]]; then
	OS_NAME="macOS"
elif [[ "$(uname -s)" == "Linux" ]]; then
	if $(lsb_release -d | grep -qF 'Ubuntu'); then
		OS_NAME="Ubuntu"
	elif $(lsb_release -d | grep -qF 'Manjaro'); then
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
		echo -e "${BOLDWHITE}Run existing script ${BOLDGREEN}\"$SCRIPT_DIR/setup_${OS_NAME}.sh\"${BOLDWHITE}.${RESET}"
		bash "$SCRIPT_DIR/setup_${OS_NAME}.sh"
		exit
	fi
fi

# Download and run
if [[ -x "$(command -v wget)" ]]; then
	echo -e "${BOLDWHITE}Download and run script via ${BOLDGREEN}wget${BOLDWHITE}.${RESET}"
	bash -c "$(wget -O - https://raw.githubusercontent.com/XuehaiPan/OS-Setup/master/setup_${OS_NAME}.sh)"
elif [[ -x "$(command -v curl)" ]]; then
	echo -e "${BOLDWHITE}Download and run script via ${BOLDGREEN}curl${BOLDWHITE}.${RESET}"
	bash -c "$(curl -fL https://raw.githubusercontent.com/XuehaiPan/OS-Setup/master/setup_${OS_NAME}.sh)"
elif [[ -x "$(command -v git)" ]]; then
	echo -e "${BOLDWHITE}Download and run script via ${BOLDGREEN}git${BOLDWHITE}.${RESET}"
	git clone --depth=1 https://github.com/XuehaiPan/OS-Setup.git
	bash "OS-Setup/setup_${OS_NAME}.sh"
else
	echo -e "${BOLDWHITE}Please download the script from ${BOLDYELLOW}https://github.com/XuehaiPan/OS-Setup${BOLDWHITE} manually.${RESET}"
fi
