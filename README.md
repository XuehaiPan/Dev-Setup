# OS-Setup

Bash scripts for setting up a newly installed OS automatically.

- [OS-Setup](#os-setup)
  - [Usage](#usage)
    - [Installation](#installation)
    - [Restoration](#restoration)
    - [Upgrade Packages](#upgrade-packages)
    - [Font Settings](#font-settings)
  - [Customization](#customization)
  - [Packages](#packages)
  - [Screenshots](#screenshots)

## Usage

### Installation

Download the script file using [wget](https://www.gnu.org/software/wget/) / [curl](https://curl.haxx.se) / [git](https://git-scm.com) or any browser ([click to download zip](https://codeload.github.com/XuehaiPan/OS-Setup/zip/master)). And then open `Terminal` and run:

**via wget**
```shell
# Download and run via wget
bash -c "$(wget -O - https://raw.githubusercontent.com/XuehaiPan/OS-Setup/master/setup.sh)"
```

**via curl**
```shell
# Download and run via curl
bash -c "$(curl -fL https://raw.githubusercontent.com/XuehaiPan/OS-Setup/master/setup.sh)"
```

**via git**
```shell
# Download via git
git clone --depth=1 https://github.com/XuehaiPan/OS-Setup.git

# Run the script file
cd OS-Setup
bash setup.sh
```

**Note**: If you are using **WSL on Windows**, you need to run [Windows Terminal](https://github.com/Microsoft/Terminal) as **administrator** to get the permissions to unpack fonts to `C:\Windows\Fonts`. Otherwise, the fonts will not be installed successfully on Windows. You can download them from [nerdfonts.com](https://www.nerdfonts.com) and install them manually.

- After running the script, all the old configuration files involved will be backed up to the folder `$HOME/.dotfiles/backups/$DATETIME`, and a symbolic link `$HOME/.dotfiles/backups/latest` links to the latest one. You can compare the differences using:

  ```shell
  # Compare the differences
  colordiff -uEB ~/.dotfiles/backups/latest ~/.dotfiles
  colordiff -uEB ~/.dotfiles/backups/latest/.dotfiles ~/.dotfiles

  # Ignore miscellaneous directories
  colordiff -uEB -x 'backups' -x '.dotfiles' ~/.dotfiles/backups/latest ~/.dotfiles
  colordiff -uEB -x 'backups' ~/.dotfiles/backups/latest/.dotfiles ~/.dotfiles
  ```

  There is a nice way to inspect and move changes from one version to another version of the same file using [`vimdiff`](https://www.vim.org) or [`meld`](http://meldmerge.org). Run:

  ```shell
  # Inspect and move changes using vimdiff
  vimdiff ~/.dotfiles/$FILE ~/.dotfiles/backups/latest/.dotfiles/$FILE
  ```

  You can get vimdiff reference manual from [https://vimhelp.org/diff.txt.html](https://vimhelp.org/diff.txt.html), or type command `:help diff` inside vim.

### Restoration

You can restore your previous dotfiles using:

```shell
# Restore the latest backup in "$HOME/.dotfiles/backups/latest"
bash restore_dotfiles.sh

# Restore a specific version
bash restore_dotfiles.sh "$HOME/.dotfiles/backups/$DATETIME"
```

**Note**: the packages installed by [`setup.sh`](setup.sh) (see section [Packages](#packages)) will remain in your system.

### Upgrade Packages

You can upgrade your packages just by running:

```shell
upgrade_packages
```

By default, `upgrade_packages` will not upgrade your conda environments. If you want to always keep your conda up-to-date, you can uncomment the corresponding line in the script. Or run the script as:

```shell
upgrade_packages; upgrade_conda
```

The function definitions are in `$HOME/.dotfiles/utilities.sh`, which will be sourced automatically when the shell starts up.

### Font Settings

The default shell for the current user will be set to **`zsh`**. In order to get a wonderful and enjoyable terminal experience, please change your terminal font to a [**Nerd Font**](https://github.com/ryanoasis/nerd-fonts). You can download any nerd font you like from [nerdfonts.com](https://www.nerdfonts.com) manually. The script will download and install [**`DejaVu Sans Mono Nerd Font`**](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DejaVuSansMono) for **macOS**, **Linux** and **Windows**. (Administrator permissions are required to install fonts on Windows)

Configure your terminal to use nerd fonts:

- For macOS and Linux users, change the terminal font setting to "Nerd Font Complete" (e.g. `'DejaVuSansMono Nerd Font Book'`).
- For WSL on Windows users, change the terminal font setting to "Nerd Font Complete Windows Compatible" (e.g. `'DejaVuSansMono NF'`).

See [Font configurations for Powerlevel10k](https://github.com/romkatv/powerlevel10k#fonts) for more details.

Or use the Powerlevel10k lean theme:

```shell
chsh --shell /usr/local/bin/zsh-purepower
```

which do not need additional font settings.

## Customization

Add a new config file to the script:

1. copy the contents of the config file to a temp file `temp.txt`;
2. replace all the identifiers of your home directory with `$HOME` in `temp.txt`;
3. replace all the identifiers of your user name with `$USER` in `temp.txt`;
4. replace all `\` with `\\` in `temp.txt`;
5. replace all `$` with `\$` in `temp.txt`;
6. add the following lines to the script:

```shell
cd $HOME   # this line has already been added at the top of the script

# replace ${cfg_file_name} with the config file's name
backup_dotfiles ${cfg_file_name} .dotfiles/${cfg_file_name}

cat >.dotfiles/${cfg_file_name} <<EOF
# paste the contents in the temp file `temp.txt` here
EOF

ln -sf .dotfiles/${cfg_file_name} .
```

7. add `${cfg_file_name}` and `.dotfiles/${cfg_file_name}` to `DOTFILES` in [`restore_dotfiles.sh`](restore_dotfiles.sh#L12).

## Packages

The source of package managers (HomeBrew (macOS), APT (Ubuntu), Pacman (Manjaro), CPAN, Gem, Conda and Pip) will be set to the open source mirrors at [TUNA](https://mirrors.tuna.tsinghua.edu.cn).

The following packages will be setup:

| Package                                                                                                                          | macOS | Ubuntu Linux | Manjaro Linux |
| :------------------------------------------------------------------------------------------------------------------------------- | :---: | :----------: | :-----------: |
| [Mirrors at TUNA](https://mirrors.tuna.tsinghua.edu.cn)                                                                          |   ✔   |      ✔       |       ✔       |
| [HomeBrew (macOS)](https://brew.sh)                                                                                              |   ✔   |      ✘       |       ✘       |
|                                                                                                                                  |       |              |               |
| [bash](https://www.gnu.org/software/bash/)                                                                                       |   ✔   |      ✔       |       ✔       |
| [bash-completion](https://salsa.debian.org/debian/bash-completion)                                                               |   ✔   |      ✔       |       ✔       |
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
| [fzf](https://github.com/junegunn/fzf)                                                                                           |   ✔   |      ✔       |       ✔       |
| [ranger](https://ranger.github.io)                                                                                               |   ✔   |      ✔       |       ✔       |
| [fd](https://github.com/sharkdp/fd)                                                                                              |   ✔   |      ✔       |       ✔       |
| [bat](https://github.com/sharkdp/bat)                                                                                            |   ✔   |      ✔       |       ✔       |
| [highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php)                                                           |   ✔   |      ✔       |       ✔       |
| [ripgrep](https://github.com/BurntSushi/ripgrep)                                                                                 |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [wget](https://www.gnu.org/software/wget/)                                                                                       |   ✔   |      ✔       |       ✔       |
| [curl](https://curl.haxx.se)                                                                                                     |   ✔   |      ✔       |       ✔       |
| [openssh](https://www.ssh.com/ssh/openssh/)                                                                                      |   ✔   |      ✔       |       ✔       |
| [ruby](https://www.ruby-lang.org/en/) & [rubygems](https://rubygems.org)                                                         |   ✔   |      ✔       |       ✔       |
| [perl](https://www.perl.org) & [cpan](https://www.cpan.org)                                                                      |   ✔   |      ✔       |       ✔       |
| [htop](https://hisham.hm/htop/)                                                                                                  |   ✔   |      ✔       |       ✔       |
| [net-tools](https://sourceforge.net/projects/net-tools/)                                                                         |   ✔   |      ✔       |       ✔       |
| [exfat-utils](https://pkgs.org/download/exfat-utils)                                                                             |   ✔   |      ✔       |       ✔       |
| [tree](http://mama.indstate.edu/users/ice/tree/)                                                                                 |   ✔   |      ✔       |       ✔       |
| [git-extras](https://github.com/tj/git-extras)                                                                                   |   ✔   |      ✔       |       ✔       |
| [diffutils](https://www.gnu.org/software/diffutils/)                                                                             |   ✔   |      ✔       |       ✔       |
| [colordiff](https://www.colordiff.org)                                                                                           |   ✔   |      ✔       |       ✔       |
| [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)                                                                       |   ✔   |      ✔       |       ✔       |
| [shfmt](https://github.com/mvdan/sh)                                                                                             |   ✔   |      ✔       |       ✔       |
| [shellcheck](https://www.shellcheck.net)                                                                                         |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [Miniconda3](https://docs.conda.io/en/latest/miniconda.html)                                                                     |   ✔   |      ✔       |       ✔       |
| [gcc](https://gcc.gnu.org)                                                                                                       |   ✔   |      ✔       |       ✔       |
| [gdb](https://www.gnu.org/software/gdb/)                                                                                         |   ✔   |      ✔       |       ✔       |
| [clang](https://clang.llvm.org) & [llvm](https://llvm.org)                                                                       |   ✔   |      ✔       |       ✔       |
| [lldb](http://lldb.llvm.org)                                                                                                     |   ✔   |      ✔       |       ✔       |
| [make](https://www.gnu.org/software/make/)                                                                                       |   ✔   |      ✔       |       ✔       |
| [cmake](https://cmake.org)                                                                                                       |   ✔   |      ✔       |       ✔       |
| [automake](https://www.gnu.org/software/automake/)                                                                               |   ✔   |      ✔       |       ✔       |
| [autoconf](https://www.gnu.org/software/autoconf/)                                                                               |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [DejaVu Sans Mono Nerd Font](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DejaVuSansMono)                   |   ✔   |      ✔       |       ✔       |
| [Cascadia Code Font](https://github.com/microsoft/cascadia-code)                                                                 |   ✔   |      ✔       |       ✔       |
| [Menlo Font](https://github.com/XuehaiPan/OS-Setup/blob/master/Menlo.zip)                                                        |   ✔   |      ✔       |       ✔       |

Currently macOS only casks installed by HomeBrew:

| Package                                                   | Description                                                                                | macOS | Ubuntu / Manjaro Linux |
| :-------------------------------------------------------- | ------------------------------------------------------------------------------------------ | :---: | :--------------------: |
| [iTerm2](https://iterm2.com)                              | A terminal emulator for macOS that does amazing things                                     |   ✔   |           ✘            |
| [Google Chrome](https://www.google.com/chrome/index.html) | A fast, secure, and free web browser built for the modern web                              |   ✔   |           ✘            |
| [Keka](https://www.keka.io)                               | The macOS file archiver                                                                    |   ✔   |           ✘            |
| [NetEase Music](https://music.163.com)                    | A freemium music streaming service                                                         |   ✔   |           ✘            |
| [IINA](https://iina.io)                                   | The modern media player for macOS                                                          |   ✔   |           ✘            |
| [Typora](https://typora.io)                               | A truly minimal markdown editor                                                            |   ✔   |           ✘            |
| [Transmission](https://transmissionbt.com)                | A fast, easy, and free BitTorrent client                                                   |   ✔   |           ✘            |
| [TeamViewer](https://www.teamviewer.com/)                 | The world’s most-loved remote desktop tool                                                 |   ✔   |           ✘            |
| [Visual Studio Code](https://code.visualstudio.com)       | A lightweight but powerful source code editor                                              |   ✔   |           ✘            |
| [XQuartz](https://www.xquartz.org)                        | An open-source effort to develop a version of the X.Org X Window System that runs on macOS |   ✔   |           ✘            |

## Screenshots

Shell:

![shell](https://raw.githubusercontent.com/XuehaiPan/OS-Setup/2c0039813cd1fe82f7dd3127ec0d40056f2cfc65/screenshots/shell.png)

Tmux:

![tmux](https://raw.githubusercontent.com/XuehaiPan/OS-Setup/2c0039813cd1fe82f7dd3127ec0d40056f2cfc65/screenshots/tmux.png)

Fzf:

![fzf](https://raw.githubusercontent.com/XuehaiPan/OS-Setup/2c0039813cd1fe82f7dd3127ec0d40056f2cfc65/screenshots/fzf.gif)

Vim:

![vim](https://raw.githubusercontent.com/XuehaiPan/OS-Setup/2c0039813cd1fe82f7dd3127ec0d40056f2cfc65/screenshots/vim.png)

Live markdown preview support for vim:

![markdown](https://raw.githubusercontent.com/XuehaiPan/OS-Setup/2c0039813cd1fe82f7dd3127ec0d40056f2cfc65/screenshots/vim-markdown.png)
