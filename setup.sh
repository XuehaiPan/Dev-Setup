#!/usr/bin/env bash

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
	echo "The operating system is not supported yet." >&2
	exit 1
fi

echo "Operating System: $OS_NAME"

# Run script if it exists
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -x "$SCRIPT_DIR/setup_${OS_NAME}.sh" && "$(basename "$0")" == "setup.sh" ]]; then
	if [[ -d "$SCRIPT_DIR/.git" || "$(basename "$SCRIPT_DIR")" == "OS-Setup-master" ]]; then
		echo "Run existing script "$SCRIPT_DIR/setup_${OS_NAME}.sh"."
		bash "$SCRIPT_DIR/setup_${OS_NAME}.sh"
		exit
	fi
fi

# Download and run
if [[ -x "$(command -v wget)" ]]; then
	echo "Download and run script via wget."
	bash -c "$(wget -qO- https://raw.githubusercontent.com/XuehaiPan/OS-Setup/master/setup_${OS_NAME}.sh)"
elif [[ -x "$(command -v curl)" ]]; then
	echo "Download and run script via curl."
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/XuehaiPan/OS-Setup/master/setup_${OS_NAME}.sh)"
elif [[ -x "$(command -v git)" ]]; then
	echo "Download and run script via git."
	git clone https://github.com/XuehaiPan/OS-Setup.git
	bash "OS-Setup/setup_${OS_NAME}.sh"
else
	echo "Please download the script from https://github.com/XuehaiPan/OS-Setup."
fi
