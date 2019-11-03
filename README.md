# OS-Setup

Bash scripts for setting up a freshly new installed OS automatically.

- [OS-Setup](#os-setup)
    - [Usage](#usage)
    - [Customization](#customization)
    - [Packages](#packages)

## Usage

Open Terminal and run:

```shell
bash setup_${OS_name}.sh
```

change the user profiles in `$HOME/.gitconfig` after the script is done.

If using Linux, modify the default user name and host name in function `send_to_mac` and `receive_from_mac` in `$HOME/.dotfiles/utilities.sh`.

After running the script, the default shell for the current user will be set to `zsh`, and all the old configuration files involved will be backed up to the folder `$HOME/.dotfiles/backups`.

Also, the script will create a shell script `upgrade_packages.sh` at your home directory. You can upgrade your packages just run:

```shell
zsh ~/upgrade_packages.sh
```

## Customization

Add new config file to the script:

1. copy the contents of the config file to a temp file `temp.txt`;
2. change the identifier of your home directory to `$HOME`;
3. change the identifier of your user name to `$USER`;
4. replace all `\` in `temp.txt` to `\\`;
5. replace all `$` in `temp.txt` to `\$`;
6. add the following to the script:

```shell
cd $HOME   # this line has already been added at the top of the script

# change ${cfg_file_name} to the config file's name
backup_dotfiles ${cfg_file_name} ./dotfiles/${cfg_file_name}

cat >.dotfiles/${cfg_file_name} <<EOF
# Paste the contents in the file `temp.txt` here.
EOF

ln -sf .dotfiles/${cfg_file_name} .
```

## Packages

The source of package managers (HomeBrew (macOS), APT (Ubuntu) and Pacman (Manjaro)) will be set to the open source mirrors at [TUNA](https://mirrors.tuna.tsinghua.edu.cn).

The following packages will be setup:

| Package                            | macOS | Ubuntu Linux | Manjaro Linux |
| :--------------------------------- | :---: | :----------: | :-----------: |
| Mirrors at TUNA                    |   ✔   |      ✔       |       ✔       |
| HomeBrew                           |   ✔   |      ✘       |       ✘       |
|                                    |       |              |               |
| bash                               |   ✔   |      ✔       |       ✔       |
| zsh & oh-my-zsh                    |   ✔   |      ✔       |       ✔       |
| powerlevel10k                      |   ✔   |      ✔       |       ✔       |
| zsh-syntax-highlighting            |   ✔   |      ✔       |       ✔       |
| zsh-autosuggestions                |   ✔   |      ✔       |       ✔       |
| zsh-completions                    |   ✔   |      ✔       |       ✔       |
| colorls                            |   ✔   |      ✔       |       ✔       |
|                                    |       |              |               |
| git & git-lfs                      |   ✔   |      ✔       |       ✔       |
| vim & vim-plug                     |   ✔   |      ✔       |       ✔       |
| tmux & oh-my-tmux                  |   ✔   |      ✔       |       ✔       |
| reattach-to-user-namespace / xclip |   ✔   |      ✔       |       ✔       |
|                                    |       |              |               |
| wget & curl                        |   ✔   |      ✔       |       ✔       |
| ssh / openssh                      |   ✔   |      ✔       |       ✔       |
| ruby & gem                         |   ✔   |      ✔       |       ✔       |
| perl & cpan                        |   ✔   |      ✔       |       ✔       |
| htop                               |   ✔   |      ✔       |       ✔       |
| net-tools                          |   ✔   |      ✔       |       ✔       |
| exfat-utils                        |   ✔   |      ✔       |       ✔       |
|                                    |       |              |               |
| Miniconda3                         |   ✔   |      ✔       |       ✔       |
| gcc                                |   ✔   |      ✔       |       ✔       |
| gdb                                |   ✔   |      ✔       |       ✔       |
| clang & llvm                       |   ✔   |      ✔       |       ✔       |
| gdb & lldb                         |   ✔   |      ✔       |       ✔       |
| make & cmake                       |   ✔   |      ✔       |       ✔       |
|                                    |       |              |               |
| DejaVu Sans Mono Nerd Font         |   ✔   |      ✔       |       ✔       |
| Cascadia Font                      |   ✔   |      ✔       |       ✔       |
| Menlo Font                         |   ✔   |      ✔       |       ✔       |

Currently macOS only casks:

| Package            | macOS | Ubuntu Linux | Manjaro Linux |
| :----------------- | :---: | :----------: | :-----------: |
| HomeBrew           |   ✔   |      ✘       |       ✘       |
| iTerm2             |   ✔   |      ✘       |       ✘       |
| Google Chrome      |   ✔   |      ✘       |       ✘       |
| Keka               |   ✔   |      ✘       |       ✘       |
| Sogouinput         |   ✔   |      ✘       |       ✘       |
| Typora             |   ✔   |      ✘       |       ✘       |
| Transmission       |   ✔   |      ✘       |       ✘       |
| Teamviewer         |   ✔   |      ✘       |       ✘       |
| Visual Studio Code |   ✔   |      ✘       |       ✘       |
| Xquartz            |   ✔   |      ✘       |       ✘       |
| Oracle-JDK         |   ✔   |      ✘       |       ✘       |
