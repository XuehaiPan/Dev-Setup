# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco config set commandExecutionTimeoutSeconds 0
$Env:ChocolateyToolsLocation='C:\Tools'
[Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', 'C:\Tools', 'Machine')

# Install PowerShell Core
choco install powershell-core git --yes

# Setup PowerShell
Install-Module posh-git -AcceptLicense -Confirm
Install-Module oh-my-posh -AcceptLicense -Confirm
Install-Module PSReadLine -Force -SkipPublisherCheck -AcceptLicense -Confirm
Install-Module Get-ChildItemColor -AllowClobber -AcceptLicense -Confirm
Install-Module WindowsConsoleFonts -AcceptLicense -Confirm

if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
    New-Item -Type File -Path $PROFILE.CurrentUserAllHosts -Force
}
@"
chcp 65001
Set-Culture zh-CN

Import-Module posh-git
Import-Module oh-my-posh
Import-Module PSReadLine
Import-Module Get-ChildItemColor
Import-Module WindowsConsoleFonts
if (Test-Path -Path '~\Miniconda3\shell\condabin\conda-hook.ps1') {
    & '~\Miniconda3\shell\condabin\conda-hook.ps1'
}

Set-Theme AgnosterPlus
Set-PSReadlineOption -EditMode Emacs
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Function which(`$name) { Get-Command `$name | Select-Object Definition }
Function rmrf(`$item) { Remove-Item `$item -Recurse -Force }
Function mkfile(`$file) { "" | Out-File `$file -Encoding utf8 }
Function setproxy(`$proxyhost) {
    `$Env:http_proxy="http://`${proxyhost}:7890"
    `$Env:https_proxy="http://`${proxyhost}:7890"
    `$Env:ftp_proxy="http://`${proxyhost}:7890"
    `$Env:all_proxy="socks5://`${proxyhost}:7891"
}
Function resetproxy() {
    `$Env:http_proxy=""
    `$Env:https_proxy=""
    `$Env:ftp_proxy=""
    `$Env:all_proxy=""
}
Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope
Set-Alias ll Get-ChildItemColor -Option AllScope
"@ | Set-Content -Path $PROFILE.CurrentUserAllHosts -Encoding utf8

Update-SessionEnvironment
& $PROFILE.CurrentUserAllHosts

# Install Chocolatey Packages
choco install vim fzf vscode conemu mobaxterm vcxsrv --yes
choco install python3 shellcheck bat wget ripgrep mingw cmake --yes
choco install windows-adk adobereader openjdk googlechrome --yes

# Setup Vim
New-Item -Type Directory -Path ~\vimfiles\autoload -Force
(New-Object Net.WebClient).DownloadFile(
  "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim",
  $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
    "~\vimfiles\autoload\plug.vim"
  )
)

@"
set nocompatible
set backspace=indent,eol,start
syntax on
set showmode
set fileformats=unix,dos
set encoding=utf-8
filetype plugin indent on
set completeopt=menu,preview,longest
set autoindent
set smartindent
set smarttab
set tabstop=4
set shiftwidth=4
set expandtab
set list
set listchars=tab:»\ ,trail:·
set conceallevel=2
set concealcursor=""
set number
set ruler
set colorcolumn=80,100,120,140
set cursorline
set foldenable
set foldmethod=indent
set foldlevel=10
set scrolloff=3
set sidescroll=10
set linebreak
set wrap
set showmatch
set hlsearch
execute "nohlsearch"
set incsearch
set ignorecase
set smartcase
set autochdir
set visualbell
set autoread
set updatetime=200
set showcmd
set wildmenu
set wildmode=longest:list,full
set completeopt=longest,menu
set background=dark
set t_Co=256
set guifont=DejaVuSansMono\ NF:h10
colorscheme desert
source `$VIMRUNTIME/delmenu.vim
source `$VIMRUNTIME/menu.vim

if &term =~ "xterm"
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_SR = "\<Esc>]50;CursorShape=2\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

autocmd GUIEnter * set lines=50 columns=160

autocmd GUIEnter * set spell spelllang=en_us

autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("`$") | execute "normal! g'\"" | endif
autocmd BufWritePre,FileWritePre * RemoveTrailingSpaces
autocmd Filetype sh,zsh,gitconfig,c,cpp,make,go set noexpandtab
autocmd FileType vim,tex let b:autoformat_autoindent = 0

let g:NERDTreeMouseMode = 2
let g:NERDTreeShowBookmarks = 1
let g:NERDTreeShowFiles = 1
let g:NERDTreeShowHidden = 1
let g:NERDTreeShowLineNumbers = 0
let g:NERDTreeWinPos = 'left'
let g:NERDTreeWinSize = 31
autocmd VimEnter * let width = winwidth('%') |
                 \ let numberwidth = ((&number || &relativenumber)? max([&numberwidth, strlen(line('$')) + 1]) : 0) |
                 \ let signwidth = ((&signcolumn == 'yes' || &signcolumn == 'auto')? 2 : 0) |
                 \ let foldwidth = &foldcolumn |
                 \ let bufwidth = width - numberwidth - foldwidth - signwidth |
                 \ if bufwidth > 80 + NERDTreeWinSize |
                 \     NERDTree |
                 \     wincmd p |
                 \ endif |
                 \ unlet width numberwidth signwidth foldwidth bufwidth
autocmd BufEnter * if (winnr('`$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree()) |
                 \ quit |
                 \ endif

let g:airline#extensions#tabline#enabled = 1

let g:bufferline_echo = 0

if &diff
    let &diffexpr = 'EnhancedDiff#Diff("git diff", "--diff-algorithm=histogram")'
endif

let g:indentLine_char_list = ['|', '¦', '┆', '┊']

let g:fzf_buffers_jump = 1
let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'
let g:fzf_tags_command = 'ctags -R'
let g:fzf_commands_expect = 'alt-enter,ctrl-x'

let g:indentLine_setConceal = 0

let g:rainbow_active = 1

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_loc_list_height = 5
let g:syntastic_check_on_wq = 0
autocmd GUIEnter * let g:syntastic_check_on_open = 1

let g:tex_flavor = 'latex'

if ! exists('`$SSH_CONNECTION')
    let g:mkdp_auto_start = 1
endif

call plug#begin('~/vimfiles/plugged')
    Plug 'flazz/vim-colorschemes'
    Plug 'mhinz/vim-startify'
    Plug 'scrooloose/nerdtree'
    Plug 'scrooloose/nerdcommenter'
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'bling/vim-bufferline'
    Plug 'ryanoasis/vim-devicons'
    Plug 'chrisbra/vim-diff-enhanced'
    Plug 'yggdroot/indentline'
    Plug 'luochen1990/rainbow'
    Plug 'jaxbot/semantic-highlight.vim'
    Plug 'chrisbra/Colorizer'
    Plug 'jiangmiao/auto-pairs'
    Plug 'tpope/vim-surround'
    Plug 'mg979/vim-visual-multi'
    Plug 'mbbill/undotree'
    Plug 'airblade/vim-gitgutter'
    Plug 'tpope/vim-fugitive'
    Plug 'liuchengxu/vista.vim'
    Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim'
    Plug 'Chiel92/vim-autoformat'
    Plug 'vim-syntastic/syntastic'
    Plug 'SirVer/ultisnips'
    Plug 'honza/vim-snippets'
    Plug 'PProvost/vim-ps1'
    Plug 'elzr/vim-json'
    Plug 'godlygeek/tabular'
    Plug 'plasticboy/vim-markdown'
    Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }
    Plug 'lervag/vimtex'
call plug#end()
"@ | Set-Content -Path ~\_vimrc -Encoding utf8

vim -c "PlugInstall | PlugUpgrade | PlugUpdate | quitall"
