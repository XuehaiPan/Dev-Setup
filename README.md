# OS-Setup

Bash scripts for setting up a newly installed OS automatically. ([screenshots](#screenshots))

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

Download the script file using [wget](https://www.gnu.org/software/wget) / [curl](https://curl.haxx.se) / [git](https://git-scm.com) or any browser ([click here to download zip](https://codeload.github.com/XuehaiPan/OS-Setup/zip/master)). And then open `Terminal` and run:

**via wget**
```bash
# Download and run via wget
bash -c "$(wget -O - https://github.com/XuehaiPan/OS-Setup/raw/master/setup.sh)"
```

**via curl**
```bash
# Download and run via curl
bash -c "$(curl -fL https://github.com/XuehaiPan/OS-Setup/raw/master/setup.sh)"
```

**via git or browser**
```bash
# Download via git
git clone --depth=1 https://github.com/XuehaiPan/OS-Setup.git

# Run the script file
cd OS-Setup
bash setup.sh
```

Options:

- `SET_MIRRORS` (default `false`) : set source of package managers to the open source mirrors at [TUNA (China)](https://mirrors.tuna.tsinghua.edu.cn) to speed up downloading. (see [Packages](#packages) for more details). If you want to bypass the prompt, run:

  ```bash
  # Bypass the prompt
  SET_MIRRORS=true bash setup.sh    # set mirrors to TUNA (China) (recommended for users in China)
  SET_MIRRORS=false bash setup.sh   # do not modify mirror settings
  ```

**Note**: If you are using **WSL on Windows**, you need to run [Windows Terminal](https://github.com/Microsoft/Terminal) as **administrator** to get the permissions to copy fonts to `C:\Windows\Fonts`. Otherwise, the fonts will not be installed successfully on Windows. You can download them from [nerdfonts.com](https://www.nerdfonts.com) and install them manually. See section [Font Settings](#font-settings) for more details.

After running the script, all the old configuration files involved will be backed up to the folder `$HOME/.dotfiles/backups/<DATETIME>`, and a symbolic link `$HOME/.dotfiles/backups/latest` links to the latest one. You can compare the differences using:

  ```bash
  # Compare the differences
  colordiff -uEB ~/.dotfiles/backups/latest ~/.dotfiles
  colordiff -uEB ~/.dotfiles/backups/latest/.dotfiles ~/.dotfiles

  # Ignore miscellaneous directories
  colordiff -uEB -x 'backups' -x '.dotfiles' ~/.dotfiles/backups/latest ~/.dotfiles
  colordiff -uEB -x 'backups' ~/.dotfiles/backups/latest/.dotfiles ~/.dotfiles
  ```

  There is a nice way to inspect and move changes from one version to another version of the same file using [`vimdiff`](https://www.vim.org) or [`meld`](http://meldmerge.org). Run:

  ```bash
  # Inspect and move changes using vimdiff
  vimdiff ~/.dotfiles/<FILE> ~/.dotfiles/backups/latest/.dotfiles/<FILE>
  ```

  You can get vimdiff reference manual from [https://vimhelp.org/diff.txt.html](https://vimhelp.org/diff.txt.html), or type command `:help diff` inside Vim.

### Restoration

You can restore your previous dotfiles using:

```bash
# Restore the latest backup in "$HOME/.dotfiles/backups/latest"
bash restore_dotfiles.sh

# Restore a specific version
bash restore_dotfiles.sh "$HOME/.dotfiles/backups/<DATETIME>"
```

**Note**: the packages installed by [`setup.sh`](setup.sh) (see section [Packages](#packages)) will remain in your system.

### Upgrade Packages

You can upgrade your packages just by running:

```bash
upgrade_packages
```

By default, `upgrade_packages` will not upgrade your conda environments. If you want to always keep your conda up-to-date, you can uncomment the corresponding line in the script. Or run the script as:

```bash
upgrade_packages; upgrade_conda
```

The function definitions are in `$HOME/.dotfiles/utilities.sh`, which will be sourced automatically when the shell starts up.

### Font Settings

The default shell for the current user will be set to **`zsh`**. In order to get a wonderful and enjoyable terminal experience, please change your terminal font to a [**Nerd Font**](https://github.com/ryanoasis/nerd-fonts). You can download any nerd font you like from [nerdfonts.com](https://www.nerdfonts.com) manually. The script will download and install [**`DejaVu Sans Mono Nerd Font`**](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DejaVuSansMono) for **macOS**, **Linux** and **Windows** (*administrator privilege* is required to install fonts on Windows).

Configure your terminal to use nerd fonts:

- For macOS and Linux users, change the terminal font setting to "Nerd Font Complete" (e.g. `'DejaVuSansMono Nerd Font Book'`).
- For WSL on Windows users, change the terminal font setting to "Nerd Font Complete Windows Compatible" (e.g. `'DejaVuSansMono NF'`).

See [Font configurations for Powerlevel10k](https://github.com/romkatv/powerlevel10k#fonts) for more details.

Or use the Powerlevel10k Lean style:

```bash
chsh -s /usr/local/bin/zsh-lean
```

which do not need additional font settings.

![zsh-lean](https://user-images.githubusercontent.com/16078332/102495805-8cc45c00-40b1-11eb-8838-b5b64c434d33.png)

**Note**: If you are using **WSL on Windows**, you need to run [Windows Terminal](https://github.com/Microsoft/Terminal) as **administrator** to get the permissions to copy fonts to `C:\Windows\Fonts`. If you forgot to obtain the appropriate privileges, you can open WSL in a new terminal window with administrator privilege. Then run the following command:

```bash
find ~/.local/share/fonts -type f -name '*.[ot]t[fc]' -print \
	-exec cp -f '{}' /mnt/c/Windows/Fonts \;
```

## Customization

Add a new config file to the script:

1. copy the contents of the config file to a temp file `temp.txt`;
2. replace all the identifiers of your home directory with `$HOME` in `temp.txt`;
3. replace all the identifiers of your user name with `$USER` in `temp.txt`;
4. replace all `\` with `\\` in `temp.txt`;
5. replace all `$` with `\$` in `temp.txt`;
6. add the following lines to the script:

```bash
cd $HOME   # this line has already been added at the top of the script

# Replace <CFG_FILE> with the config file's name
backup_dotfiles <CFG_FILE> .dotfiles/<CFG_FILE>

cat >.dotfiles/<CFG_FILE> <<EOF
# Paste the contents in the temp file `temp.txt` here
EOF

ln -sf .dotfiles/<CFG_FILE> .
```

7. add `<CFG_FILE>` and `.dotfiles/<CFG_FILE>` to `DOTFILES` in [`restore_dotfiles.sh`](restore_dotfiles.sh#L12).

## Packages

The source of package managers (Homebrew (macOS), APT (Ubuntu), Pacman (Manjaro), CPAN, Gem, Conda and Pip) will be set to the open source mirrors at [TUNA (China)](https://mirrors.tuna.tsinghua.edu.cn).

The following packages will be setup:

| Package                                                                                                                          | macOS | Ubuntu Linux | Manjaro Linux |
| :------------------------------------------------------------------------------------------------------------------------------- | :---: | :----------: | :-----------: |
| [Mirrors at TUNA (China)](https://mirrors.tuna.tsinghua.edu.cn)                                                                  |   ✔   |      ✔       |       ✔       |
| [Homebrew (macOS)](https://brew.sh)                                                                                              |   ✔   |      ✘       |       ✘       |
|                                                                                                                                  |       |              |               |
| [bash](https://www.gnu.org/software/bash)                                                                                        |   ✔   |      ✔       |       ✔       |
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
| [wget](https://www.gnu.org/software/wget)                                                                                        |   ✔   |      ✔       |       ✔       |
| [curl](https://curl.haxx.se)                                                                                                     |   ✔   |      ✔       |       ✔       |
| [openssh](https://www.ssh.com/ssh/openssh)                                                                                       |   ✔   |      ✔       |       ✔       |
| [ruby](https://www.ruby-lang.org/en) & [rubygems](https://rubygems.org)                                                          |   ✔   |      ✔       |       ✔       |
| [perl](https://www.perl.org) & [cpan](https://www.cpan.org)                                                                      |   ✔   |      ✔       |       ✔       |
| [htop](https://hisham.hm/htop)                                                                                                   |   ✔   |      ✔       |       ✔       |
| [net-tools](https://sourceforge.net/projects/net-tools)                                                                          |   ✔   |      ✔       |       ✔       |
| [exfat-utils](https://pkgs.org/download/exfat-utils)                                                                             |   ✔   |      ✔       |       ✔       |
| [tree](http://mama.indstate.edu/users/ice/tree/)                                                                                 |   ✔   |      ✔       |       ✔       |
| [git-extras](https://github.com/tj/git-extras)                                                                                   |   ✔   |      ✔       |       ✔       |
| [diffutils](https://www.gnu.org/software/diffutils)                                                                              |   ✔   |      ✔       |       ✔       |
| [colordiff](https://www.colordiff.org)                                                                                           |   ✔   |      ✔       |       ✔       |
| [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)                                                                       |   ✔   |      ✔       |       ✔       |
| [shfmt](https://github.com/mvdan/sh)                                                                                             |   ✔   |      ✔       |       ✔       |
| [shellcheck](https://www.shellcheck.net)                                                                                         |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [Miniconda3](https://docs.conda.io/en/latest/miniconda.html)                                                                     |   ✔   |      ✔       |       ✔       |
| [gcc](https://gcc.gnu.org)                                                                                                       |   ✔   |      ✔       |       ✔       |
| [gdb](https://www.gnu.org/software/gdb)                                                                                          |   ✔   |      ✔       |       ✔       |
| [clang](https://clang.llvm.org) & [llvm](https://llvm.org)                                                                       |   ✔   |      ✔       |       ✔       |
| [lldb](http://lldb.llvm.org)                                                                                                     |   ✔   |      ✔       |       ✔       |
| [make](https://www.gnu.org/software/make)                                                                                        |   ✔   |      ✔       |       ✔       |
| [cmake](https://cmake.org)                                                                                                       |   ✔   |      ✔       |       ✔       |
| [automake](https://www.gnu.org/software/automake)                                                                                |   ✔   |      ✔       |       ✔       |
| [autoconf](https://www.gnu.org/software/autoconf)                                                                                |   ✔   |      ✔       |       ✔       |
|                                                                                                                                  |       |              |               |
| [DejaVu Sans Mono Nerd Font](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DejaVuSansMono)                   |   ✔   |      ✔       |       ✔       |
| [Cascadia Code Font](https://github.com/microsoft/cascadia-code)                                                                 |   ✔   |      ✔       |       ✔       |
| [Menlo Font](https://github.com/XuehaiPan/OS-Setup/blob/master/Menlo.zip)                                                        |   ✔   |      ✔       |       ✔       |

Currently macOS only casks installed by Homebrew:

| Package                                                   | Description                                                                                | macOS | Ubuntu / Manjaro Linux |
| :-------------------------------------------------------- | ------------------------------------------------------------------------------------------ | :---: | :--------------------: |
| [iTerm2](https://iterm2.com)                              | A terminal emulator for macOS that does amazing things                                     |   ✔   |           ✘            |
| [Google Chrome](https://www.google.com/chrome/index.html) | A fast, secure, and free web browser built for the modern web                              |   ✔   |           ✘            |
| [Keka](https://www.keka.io)                               | The macOS file archiver                                                                    |   ✔   |           ✘            |
| [IINA](https://iina.io)                                   | The modern media player for macOS                                                          |   ✔   |           ✘            |
| [Typora](https://typora.io)                               | A truly minimal markdown editor                                                            |   ✔   |           ✘            |
| [Visual Studio Code](https://code.visualstudio.com)       | A lightweight but powerful source code editor                                              |   ✔   |           ✘            |
| [XQuartz](https://www.xquartz.org)                        | An open-source effort to develop a version of the X.Org X Window System that runs on macOS |   ✔   |           ✘            |

## Screenshots

Shell:

![shell](https://user-images.githubusercontent.com/16078332/101635454-f6ff5000-3a64-11eb-9b4a-af674432dc69.png)

tmux:

![tmux](https://user-images.githubusercontent.com/16078332/102495801-8afa9880-40b1-11eb-9d3f-5045c37fd576.png)

fzf:

![fzf](https://user-images.githubusercontent.com/16078332/101661628-7ac83500-3a83-11eb-80a1-77c772abe2a4.gif)

Vim:

![vim](https://user-images.githubusercontent.com/16078332/101630446-d7b0f480-3a5d-11eb-9d2a-af9d09f0d2c0.png)

Live markdown preview support for Vim:

![markdown](https://user-images.githubusercontent.com/16078332/101730862-bc91c380-3af5-11eb-82a0-1d3f4e75481d.gif)
