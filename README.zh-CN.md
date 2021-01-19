# Dev-Setup

[English Version](README.md) 👈

基本开发环境自动化设置脚本。（[屏幕截图](#屏幕截图)）

**目录**

- [使用方法](#使用方法)
  - [安装](#安装)
  - [回滚旧设置](#回滚旧设置)
  - [更新软件包](#更新软件包)
  - [字体设置](#字体设置)
- [个性化设置](#个性化设置)
- [软件包列表](#软件包列表)
- [屏幕截图](#屏幕截图)

## 使用方法

### 安装

使用 [wget](https://www.gnu.org/software/wget) / [curl](https://curl.haxx.se) / [git](https://git-scm.com) 或浏览器（[点此下载 zip](https://codeload.github.com/XuehaiPan/Dev-Setup/zip/master)）下载本脚本。打开 `终端` 运行如下命令：

**via wget**

```bash
# Download and run via wget
/bin/bash -c "$(wget -O - https://github.com/XuehaiPan/Dev-Setup/raw/master/setup.sh)"
```

**via curl**

```bash
# Download and run via curl
/bin/bash -c "$(curl -fL https://github.com/XuehaiPan/Dev-Setup/raw/master/setup.sh)"
```

**via git or browser**

```bash
# Download via git
git clone --depth=1 https://github.com/XuehaiPan/Dev-Setup.git

# Run the script file
cd Dev-Setup
/bin/bash setup.sh
```

选项：

- `SET_MIRRORS` (默认值 `false`)：将软件包管理器的源设置为开源镜像 [TUNA (China)](https://mirrors.tuna.tsinghua.edu.cn) 以加速下载（更多信息请参见 [软件包列表](#软件包列表)）。如果你想跳过询问步骤，请运行：

  ```bash
  # Bypass the prompt
  SET_MIRRORS=true bash setup.sh    # set mirrors to TUNA (China) (recommended for users in China)
  SET_MIRRORS=false bash setup.sh   # do not modify mirror settings
  ```

**注**：如果你使用的是 Windows 上的 **WSL (Windows Subsystem for Linux)**，你需要以 **管理员权限** 运行 [Windows Terminal](https://github.com/Microsoft/Terminal)，用以获得权限将字体文件拷贝至文件夹 `C:\Windows\Fonts`，否则将无法在 Windows 上正确安装字体文件。你可以从 [nerdfonts.com](https://www.nerdfonts.com) 下载字体并手动安装，更多信息请参见 [字体设置](#字体设置)。

脚本执行结束后，所有旧配置文件会被备份至文件夹 `$HOME/.dotfiles/backups/<DATETIME>`，并将会有一个软链接 `$HOME/.dotfiles/backups/latest` 链接至最新的备份文件夹。你可以使用如下命令比较修改：

```bash
# Compare the differences
colordiff -uEB ~/.dotfiles/backups/latest ~/.dotfiles
colordiff -uEB ~/.dotfiles/backups/latest/.dotfiles ~/.dotfiles

# Ignore miscellaneous directories
colordiff -uEB -x 'backups' -x '.dotfiles' ~/.dotfiles/backups/latest ~/.dotfiles
colordiff -uEB -x 'backups' ~/.dotfiles/backups/latest/.dotfiles ~/.dotfiles
```

使用 [`vimdiff`](https://www.vim.org) 或 [`meld`](http://meldmerge.org) 可以更方便地比较查看文件和在不同版本间拷贝修改。执行：

```bash
# Inspect and move changes using vimdiff
vim -c "DirDiff ~/.dotfiles ~/.dotfiles/backups/latest/.dotfiles"
```

你可以从 [https://vimhelp.org/diff.txt.html](https://vimhelp.org/diff.txt.html) 获得 `vimdiff` 的支持文档，或者在 Vim 中执行 `:help diff` 查看帮助。

### 回滚旧设置

你可以运行如下命令回滚旧设置：

```bash
# Rollback to the latest backup in "$HOME/.dotfiles/backups/latest"
bash restore_dotfiles.sh

# Rollback to a specific version
bash restore_dotfiles.sh "$HOME/.dotfiles/backups/<DATETIME>"
```

**注**：由脚本 [`setup.sh`](setup.sh) 安装的软件包将保留在你的系统之中。（更多信息请参见 [软件包列表](#软件包列表)）

### 更新软件包

你可以运行如下命令更新软件包：

```bash
upgrade_packages
```

在默认设置下，命令 `upgrade_packages` 不会更新 conda 环境。如果你想总是更新所有 conda 环境，可以解注释 `$HOME/.dotfiles/utilities.sh` 中对应的行。或执行以下命令：

```bash
upgrade_packages; upgrade_conda
```

### 字体设置

当前用户的默认 Shell 将被设置为 **`zsh`**。为了获得更好的终端体验，请将你的终端字体设置为 [**Nerd Font**](https://github.com/ryanoasis/nerd-fonts)。你可以从 [nerdfonts.com](https://www.nerdfonts.com) 手动下载你喜欢的字体。本脚本将为 **macOS**、**Linux** 和 **Windows** 用户自动下载安装 [**`DejaVu Sans Mono Nerd Font`**](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DejaVuSansMono)。（Windows 下安装字体需要 *管理员权限*）

将的终端字体设置为 nerd font：

- 对 macOS 和 Linux 用户，将的终端字体设置为 "Nerd Font Complete"（例如 `'DejaVuSansMono Nerd Font Book'`）。
- 对在 Windows 上使用 WSL 的用户，将的终端字体设置为 "Nerd Font Complete Windows Compatible"（例如 `'DejaVuSansMono NF'`）。

查看 [Font configurations for Powerlevel10k](https://github.com/romkatv/powerlevel10k#fonts) 获取更多信息。

或者使用 Powerlevel10k Lean style：

```bash
chsh -s /usr/local/bin/zsh-lean
```

该设置无需额外的字体设置。

![zsh-lean](https://user-images.githubusercontent.com/16078332/102495805-8cc45c00-40b1-11eb-8838-b5b64c434d33.png)

**注**：如果你使用的是 Windows 上的 **WSL (Windows Subsystem for Linux)**，你需要以 **管理员权限** 运行 [Windows Terminal](https://github.com/Microsoft/Terminal)，用以获得权限将字体文件拷贝至文件夹 `C:\Windows\Fonts`。如果你运行脚本时忘记使用管理员权限，你可以重新使用管理员权限打开一个新的终端窗口，并运行如下命令：

```bash
find ~/.local/share/fonts -type f -name '*.[ot]t[fc]' -print \
        -exec cp -f '{}' /mnt/c/Windows/Fonts \;
```

## 个性化设置

打造你自己的自动化设置脚本。向脚本中添加新设置：

1. fork 本仓库；
2. 拷贝新的配置文件的内容至一个临时文件 `temp.txt`；
3. 将 `temp.txt` 中的所有的用户文件夹符号 `~` 替换为 `$HOME`；
4. 将 `temp.txt` 中的所有的当前用户的用户名替换为 `$USER`；
5. 将 `temp.txt` 中的所有 `\` 替换为 `\\`；
6. 将 `temp.txt` 中的所有 `$` 替换为 `\$`；
7. 在脚本 `setup_<OS_NAME>.sh` 中添加如下若干行：

```bash
cd $HOME   # this line has already been added at the top of the script

# Replace <CFG_FILE> with the config file's name
backup_dotfiles <CFG_FILE> .dotfiles/<CFG_FILE>

cat >.dotfiles/<CFG_FILE> <<EOF
# Paste the contents in the temp file `temp.txt` here
EOF

ln -sf .dotfiles/<CFG_FILE> .
```

8. 将项目 `<CFG_FILE>` 和 `.dotfiles/<CFG_FILE>` 添加至脚本 [`restore_dotfiles.sh`](restore_dotfiles.sh#L12) 中的 `DOTFILES` 列表中。

## 软件包列表

软件包管理器（Homebrew (macOS)、APT (Ubuntu)、Pacman (Manjaro)、CPAN、Gem、Conda 和 Pip）的源将被设置为 [TUNA (China)](https://mirrors.tuna.tsinghua.edu.cn) 开源镜像。

本脚本将会安装和配置如下软件包：

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
| [Menlo Font](https://github.com/XuehaiPan/Dev-Setup/blob/master/Menlo.zip)                                                        |   ✔   |      ✔       |       ✔       |

仅在 macOS 上由 Homebrew 安装的 App：

| Package                                                   | Description                                                                                | macOS | Ubuntu / Manjaro Linux |
| :-------------------------------------------------------- | ------------------------------------------------------------------------------------------ | :---: | :--------------------: |
| [iTerm2](https://iterm2.com)                              | A terminal emulator for macOS that does amazing things                                     |   ✔   |           ✘            |
| [Google Chrome](https://www.google.com/chrome/index.html) | A fast, secure, and free web browser built for the modern web                              |   ✔   |           ✘            |
| [Keka](https://www.keka.io)                               | The macOS file archiver                                                                    |   ✔   |           ✘            |
| [IINA](https://iina.io)                                   | The modern media player for macOS                                                          |   ✔   |           ✘            |
| [Typora](https://typora.io)                               | A truly minimal markdown editor                                                            |   ✔   |           ✘            |
| [Visual Studio Code](https://code.visualstudio.com)       | A lightweight but powerful source code editor                                              |   ✔   |           ✘            |
| [XQuartz](https://www.xquartz.org)                        | An open-source effort to develop a version of the X.Org X Window System that runs on macOS |   ✔   |           ✘            |

## 屏幕截图

Shell：

![shell](https://user-images.githubusercontent.com/16078332/101635454-f6ff5000-3a64-11eb-9b4a-af674432dc69.png)

tmux：

![tmux](https://user-images.githubusercontent.com/16078332/102495801-8afa9880-40b1-11eb-9d3f-5045c37fd576.png)

fzf：

![fzf](https://user-images.githubusercontent.com/16078332/101661628-7ac83500-3a83-11eb-80a1-77c772abe2a4.gif)

Vim：

![vim](https://user-images.githubusercontent.com/16078332/101630446-d7b0f480-3a5d-11eb-9d2a-af9d09f0d2c0.png)

实时 Vim Markdown 预览支持：

![markdown](https://user-images.githubusercontent.com/16078332/101730862-bc91c380-3af5-11eb-82a0-1d3f4e75481d.gif)
