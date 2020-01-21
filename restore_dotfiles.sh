#!/usr/bin/env bash

BACKUP_DIR="${1:-"$HOME/.dotfiles/backups/latest"}"

if [[ ! -d "$BACKUP_DIR" ]]; then
	echo "Backup directory \"$BACKUP_DIR\" does not exist."
	exit 1
fi

echo "Restore dotfiles in backup directory \"$BACKUP_DIR\"."

DOTFILES=(
	.zshrc .dotfiles/.zshrc
	.gemrc .dotfiles/.gemrc
	.dotfiles/.zshrc-common
	.dotfiles/zsh-purepower
	.profile .dotfiles/.profile
	.bash_profile .dotfiles/.bash_profile
	.bashrc .dotfiles/.bashrc
	.vimrc .dotfiles/.vimrc
	.tmux.conf .dotfiles/.tmux.conf
	.tmux.conf.local .dotfiles/.tmux.conf.local
	.dotfiles/.tmux.conf.user
	.dotfiles/.tmux
	.gitconfig .dotfiles/.gitconfig
	.gitignore_global .dotfiles/.gitignore_global
	.condarc .dotfiles/.condarc
	.gdbinit .dotfiles/.gdbinit
	.Xdefaults .dotfiles/.Xdefaults
	.dotfiles/utilities.sh
	upgrade_packages.sh
)

cd "$HOME"

for file in "${DOTFILES[@]}"; do
	if [[ -f "$BACKUP_DIR/$file" || -d "$BACKUP_DIR/$file" ]]; then
		backup_prefix="$(dirname "$BACKUP_DIR/$file")"
		prefix="$(dirname "$HOME/$file")"
		file="$(basename "$file")"
		echo "Restore \"$file\" from \"$backup_prefix\" to \"$prefix\"."
		cp -rf "$backup_prefix/$file" "$prefix/$file"
		if [[ "$prefix" == "$HOME/.dotfiles" ]]; then
			if diff -EB "$file" ".dotfiles/$file" &>/dev/null; then
				echo "The file \"$file\" in \"$HOME\" is same as the one in \"$HOME/.dotfiles\". Make symbolic link."
				ln -sf ".dotfiles/$file" .
			fi
		fi
	fi
done
