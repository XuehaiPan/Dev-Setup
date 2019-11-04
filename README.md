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

After running the script, all the old configuration files involved will be backed up to the folder `$HOME/.dotfiles/backups/$DATETIME`.

### Upgrade Packages

The script will create a shell script named `upgrade_packages.sh` at your home directory. You can upgrade your packages just by running:

```shell
zsh ~/upgrade_packages.sh
```

By default, `upgrade_packages.sh` will not upgrade your conda environments. If you want to always keep your conda up-to-date, you can uncomment the last line in the script. Or run the script as:

```shell
source ~/upgrade_packages.sh; upgrade_conda
```

If you are using Linux, each function in `upgrade_packages.sh` has a copy in `$HOME/.dotfiles/utilities.sh` which will be sourced automatically when the shell starts up.

### Font Settings

The default shell for the current user will be set to `zsh`. In order to get a wonderful and enjoyable terminal experience, please change your terminal font to a [Nerd Font](https://github.com/ryanoasis/nerd-fonts). The script will download [`DejaVu Sans Mono Nerd Font`](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DejaVuSansMono) for macOS and Linux. If you are using WSL on Windows, you can download them from [nerdfonts.com](https://www.nerdfonts.com) manually, and change the font setting in [Windows Terminal](https://github.com/Microsoft/Terminal) profile to Nerd Font Complete Windows Compatible (e.g. `DejaVuSansMono NF`). Or use the Powerlevel10k lean theme:

```shell
chsh -s /usr/local/bin/zsh_purepower
```

See [Font configurations for Powerlevel10k](https://github.com/romkatv/powerlevel10k#fonts) for more details.

## Customization

Add a new config file to the script:

1. copy the contents of the config file to a temp file `temp.txt`;
2. replace all the identifiers of your home directory to `$HOME` in `temp.txt`;
3. replace all the identifiers of your user name to `$USER` in `temp.txt`;
4. replace all `\` to `\\` in `temp.txt`;
5. replace all `$` to `\$` in `temp.txt`;
6. add the following lines to the script:

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
| [wget](https://www.gnu.org/software/wget/)                                                                                       |   ✔   |      ✔       |       ✔       |
| [curl](https://curl.haxx.se)                                                                                                     |   ✔   |      ✔       |       ✔       |
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
| [make](https://www.gnu.org/software/make/)                                                                                       |   ✔   |      ✔       |       ✔       |
| [cmake](https://cmake.org)                                                                                                       |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [DejaVu Sans Mono Nerd Font](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DejaVuSansMono)                   |   ✔   |      ✔       |       ✔       |
| [Cascadia Code Font](https://github.com/microsoft/cascadia-code)                                                                 |   ✔   |      ✔       |       ✔       |
| Menlo Font                                                                                                                       |   ✔   |      ✔       |       ✔       |

Currently macOS only casks installed by HomeBrew:

| Package                                                                          | Description                                                                                | macOS | Ubuntu / Manjaro Linux |
| :------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | :---: | :--------------------: |
| [iTerm2](https://iterm2.com)                                                     | A terminal emulator for macOS that does amazing things                                     |   ✔   |           ✘            |
| [Google Chrome](https://www.google.com/chrome/index.html)                        | A fast, secure, and free web browser built for the modern web                              |   ✔   |           ✘            |
| [Keka](https://www.keka.io)                                                      | The macOS file archiver                                                                    |   ✔   |           ✘            |
| [Sogou Pinyin](https://pinyin.sogou.com/mac/)                                    | A popular Chinese Pinyin input method editor                                               |   ✔   |           ✘            |
| [NetEase Music](https://music.163.com)                                           | A freemium music streaming service                                                         |   ✔   |           ✘            |
| [IINA](https://iina.io)                                                          | The modern media player for macOS                                                          |   ✔   |           ✘            |
| [Typora](https://typora.io)                                                      | A truly minimal markdown editor                                                            |   ✔   |           ✘            |
| [Transmission](https://transmissionbt.com)                                       | A fast, easy, and free BitTorrent client                                                   |   ✔   |           ✘            |
| [TeamViewer](https://www.teamviewer.com/)                                        | The world’s most-loved remote desktop tool                                                 |   ✔   |           ✘            |
| [Visual Studio Code](https://code.visualstudio.com)                              | A lightweight but powerful source code editor                                              |   ✔   |           ✘            |
| [XQuartz](https://www.xquartz.org)                                               | An open-source effort to develop a version of the X.Org X Window System that runs on macOS |   ✔   |           ✘            |
| [Oracle JDK](https://www.oracle.com/technetwork/java/javase/overview/index.html) | Java™ Platform Standard Edition Development Kit                                            |   ✔   |           ✘            |
