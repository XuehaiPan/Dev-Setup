# OS-Setup

Bash scripts for setting up a freshly new installed OS automatically.

- [OS-Setup](#os-setup)
    - [Usage](#usage)
        - [Installation](#installation)
        - [Upgrade Packages](#upgrade-packages)
        - [Font Settings](#font-settings)
    - [Customization](#customization)
    - [Packages](#packages)

## Usage

### Installation

Open Terminal and run:

```shell
bash setup_${OS_name}.sh
```

change the user profiles in `$HOME/.gitconfig` after the script is done.

If you are using Linux, modify the default user name and host name in function `send_to_mac` and `receive_from_mac` in `$HOME/.dotfiles/utilities.sh`.

After running the script, all the old configuration files involved will be backed up to the folder `$HOME/.dotfiles/backups`.

### Upgrade Packages

The script will create a shell script `upgrade_packages.sh` at your home directory. You can upgrade your packages just by running:

```shell
zsh ~/upgrade_packages.sh
```

### Font Settings

The default shell for the current user will be set to `zsh`. In order to get a wonderful and enjoyable terminal experience, please change your terminal font to a nerd font. The script will download [`DejaVu Sans Mono Nerd Font`](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DejaVuSansMono) for macOS and Linux. If you are using WSL on Windows, you can download them from [nerdfonts.com](https://www.nerdfonts.com) manually. Or use the powerlevel10k lean theme:

```shell
chsh -s /usr/local/bin/zsh_purepower
```

## Customization

Add a new config file to the script:

1. copy the contents of the config file to a temp file `temp.txt`;
2. replace all the identifiers of your home directory to `$HOME` in `temp.txt`;
3. replace all the identifiers of your user name to `$USER` in `temp.txt`;
4. replace all `\` to `\\` in `temp.txt`;
5. replace all `$` to `\$` in `temp.txt`;
6. add the following to the script:

```shell
cd $HOME   # this line has already been added at the top of the script

# change ${cfg_file_name} to the config file's name
backup_dotfiles ${cfg_file_name} ./dotfiles/${cfg_file_name}

cat >.dotfiles/${cfg_file_name} <<EOF
# paste the contents in the temp file `temp.txt` here
EOF

ln -sf .dotfiles/${cfg_file_name} .
```

## Packages

The source of package managers (HomeBrew (macOS), APT (Ubuntu), Pacman (Manjaro), Gem and Conda) will be set to the open source mirrors at [TUNA](https://mirrors.tuna.tsinghua.edu.cn).

The following packages will be setup:

| Package                                                                                                                          | macOS | Ubuntu Linux | Manjaro Linux |
| :------------------------------------------------------------------------------------------------------------------------------- | :---: | :----------: | :-----------: |
| [Mirrors at TUNA](https://mirrors.tuna.tsinghua.edu.cn)                                                                          |   ✔   |      ✔       |       ✔       |
| [HomeBrew (macOS)](https://brew.sh)                                                                                              |   ✔   |      ✘       |       ✘       |
|                                                                                                                                  |       |              |               |
| [bash](https://www.gnu.org/software/bash/)                                                                                       |   ✔   |      ✔       |       ✔       |
| [zsh](http://zsh.sourceforge.net) & [oh-my-zsh](https://ohmyz.sh)                                                                |   ✔   |      ✔       |       ✔       |
| [powerlevel10k](https://github.com/romkatv/powerlevel10k)                                                                        |   ✔   |      ✔       |       ✔       |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)                                                  |   ✔   |      ✔       |       ✔       |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)                                                          |   ✔   |      ✔       |       ✔       |
| [zsh-completions](https://github.com/zsh-users/zsh-completions)                                                                  |   ✔   |      ✔       |       ✔       |
| [colorls](https://github.com/athityakumar/colorls)                                                                               |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [git](https://git-scm.com) & [git-lfs](https://git-lfs.github.com)                                                               |   ✔   |      ✔       |       ✔       |
| [vim](https://www.vim.org) & [vim-plug](https://github.com/junegunn/vim-plug)                                                    |   ✔   |      ✔       |       ✔       |
| [tmux](https://github.com/tmux/tmux/wiki) & [oh-my-tmux](https://github.com/gpakosz/.tmux)                                       |   ✔   |      ✔       |       ✔       |
| [reattach-to-user-namespace](https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard) / [xclip](https://github.com/astrand/xclip) |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [wget](https://www.gnu.org/software/wget/) & [curl](https://curl.haxx.se)                                                        |   ✔   |      ✔       |       ✔       |
| [openssh](https://www.ssh.com/ssh/openssh/)                                                                                      |   ✔   |      ✔       |       ✔       |
| [ruby](https://www.ruby-lang.org/en/) & [rubygems](https://rubygems.org)                                                         |   ✔   |      ✔       |       ✔       |
| [perl](https://www.perl.org) & [cpan](https://www.cpan.org)                                                                      |   ✔   |      ✔       |       ✔       |
| [htop](https://hisham.hm/htop/)                                                                                                  |   ✔   |      ✔       |       ✔       |
| [net-tools](https://sourceforge.net/projects/net-tools/)                                                                         |   ✔   |      ✔       |       ✔       |
| [exfat-utils](https://pkgs.org/download/exfat-utils)                                                                             |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [Miniconda3](https://docs.conda.io/en/latest/miniconda.html)                                                                     |   ✔   |      ✔       |       ✔       |
| [gcc](https://gcc.gnu.org)                                                                                                       |   ✔   |      ✔       |       ✔       |
| [gdb](https://www.gnu.org/software/gdb/)                                                                                         |   ✔   |      ✔       |       ✔       |
| [clang](https://clang.llvm.org) & [llvm](https://llvm.org)                                                                       |   ✔   |      ✔       |       ✔       |
| [lldb](http://lldb.llvm.org)                                                                                                     |   ✔   |      ✔       |       ✔       |
| [make](https://www.gnu.org/software/make/) & [cmake](https://cmake.org)                                                          |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [DejaVu Sans Mono Nerd Font](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DejaVuSansMono)                   |   ✔   |      ✔       |       ✔       |
| [Cascadia Code Font](https://github.com/microsoft/cascadia-code)                                                                 |   ✔   |      ✔       |       ✔       |
| Menlo Font                                                                                                                       |   ✔   |      ✔       |       ✔       |

Currently macOS only casks installed by HomeBrew:

| Package                                                                           | macOS | Ubuntu Linux | Manjaro Linux |
| :-------------------------------------------------------------------------------- | :---: | :----------: | :-----------: |
| [iTerm2](https://iterm2.com)                                                      |   ✔   |      ✘       |       ✘       |
| [Google Chrome](https://www.google.com/chrome/index.html)                         |   ✔   |      ✘       |       ✘       |
| [Keka](https://www.keka.io)                                                       |   ✔   |      ✘       |       ✘       |
| [Sogou Pinyin](https://pinyin.sogou.com/mac/)                                     |   ✔   |      ✘       |       ✘       |
| [Netease Music](https://music.163.com)                                            |   ✔   |      ✘       |       ✘       |
| [IINA](https://iina.io)                                                           |   ✔   |      ✘       |       ✘       |
| [Typora](https://typora.io)                                                       |   ✔   |      ✘       |       ✘       |
| [Transmission](https://transmissionbt.com)                                        |   ✔   |      ✘       |       ✘       |
| [TeamViewer](https://www.teamviewer.com/en/)                                      |   ✔   |      ✘       |       ✘       |
| [Visual Studio Code](https://code.visualstudio.com)                               |   ✔   |      ✘       |       ✘       |
| [XQuartz](https://www.xquartz.org)                                                |   ✔   |      ✘       |       ✘       |
| [Oracle JDK](https://www.oracle.com/technetwork/java/javase/downloads/index.html) |   ✔   |      ✘       |       ✘       |
