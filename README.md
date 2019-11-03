# OS-Setup

Bash scripts for setting up a freshly new installed OS automatically.

## Usage

Open Terminal and run

```bash
bash setup_${OS_name}.sh
```

change the user profiles in `.gitconfig` after the script is done.

If using Linux, modify the default host name in function `send_to_mac` and `recieve_from_mac` in file `$HOME/.dotfiles/utilities.sh`.

After running the script, all the old configuration files involved will be backed up to the folder `$HOME/.dotfiles/backups`.

## Customization

Add new config file to the script:

1. copy the contents of the config file to a temp file `temp.txt`;
2. replace all `\` in `temp.txt` to `\\`;
3. replace all `$` in `temp.txt` to `\$`;
4. add the following to the script:

```bash
cd $HOME   # this line has already been added at the top of the script

# change ${cfg_file_name} to config file's name
backup_dotfiles ${cfg_file_name} ./dotfiles/${cfg_file_name}

cat >.dotfiles/${cfg_file_name} <<EOF
# Paste the contents in the file `temp.txt` here.
EOF

ln -sf .dotfiles/${cfg_file_name} .
```
