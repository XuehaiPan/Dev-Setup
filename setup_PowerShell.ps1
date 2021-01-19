# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

# Install Chocolatey
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression -Command (New-Object -TypeName System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')

choco feature enable --name=useRememberedArgumentsForUpgrades
choco config set --name=commandExecutionTimeoutSeconds --value=0
$Env:ChocolateyToolsLocation = 'C:\Tools'
[Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', 'C:\Tools', 'Machine')

# Install PowerShell Core
choco install powershell-core git --yes

# Setup PowerShell
Install-Module -Name posh-git -AcceptLicense -Force -Confirm:$false
Install-Module -Name oh-my-posh -AcceptLicense -Force -Confirm:$false
Install-Module -Name PSReadLine -SkipPublisherCheck -AcceptLicense -Force -Confirm:$false
Install-Module -Name Get-ChildItemColor -AllowClobber -AcceptLicense -Force -Confirm:$false
Install-Module -Name WindowsConsoleFonts -AcceptLicense -Force -Confirm:$false

if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
    New-Item -Path $PROFILE.CurrentUserAllHosts -Type File -Force
}
@"
chcp 65001

Import-Module -Name posh-git -ErrorAction:Ignore
Import-Module -Name oh-my-posh -ErrorAction:Ignore
Import-Module -Name PSReadLine -ErrorAction:Ignore
Import-Module -Name Get-ChildItemColor -ErrorAction:Ignore
Import-Module -Name WindowsConsoleFonts -ErrorAction:Ignore
if (Test-Path -Path ~\Miniconda3\shell\condabin\conda-hook.ps1) {
    & ~\Miniconda3\shell\condabin\conda-hook.ps1
}

Set-Theme -Name AgnosterPlus -ErrorAction:Ignore
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function Complete

Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope
Set-Alias -Name ll -Value Get-ChildItemColor -Option AllScope
Set-Alias -Name which -Value Get-Command -Option AllScope
Function Set-Proxy(`$proxyHost = "127.0.0.1",
                   `$httpPort = 7890, `$httpsPort = 7890,
                   `$ftpPort = 7890, `$socksPort = 7891) {
    `$Env:http_proxy = "http://`${proxyHost}:`${httpPort}"
    `$Env:https_proxy = "http://`${proxyHost}:`${httpsPort}"
    `$Env:ftp_proxy = "http://`${proxyHost}:`${ftpPort}"
    `$Env:all_proxy = "socks5://`${proxyHost}:`${socksPort}"
    `$Env:HTTP_PROXY = "http://`${proxyHost}:`${httpPort}"
    `$Env:HTTPS_PROXY = "http://`${proxyHost}:`${httpsPort}"
    `$Env:FTP_PROXY = "http://`${proxyHost}:`${ftpPort}"
    `$Env:ALL_PROXY = "socks5://`${proxyHost}:`${socksPort}"
    [Environment]::SetEnvironmentVariable('http_proxy', "http://`${proxyHost}:`${httpPort}", 'User')
    [Environment]::SetEnvironmentVariable('https_proxy', "http://`${proxyHost}:`${httpsPort}", 'User')
    [Environment]::SetEnvironmentVariable('ftp_proxy', "http://`${proxyHost}:`${ftpPort}", 'User')
    [Environment]::SetEnvironmentVariable('all_proxy', "socks5://`${proxyHost}:`${socksPort}", 'User')

    `$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path `$regKey -Name ProxyEnable -Value 1
    Set-ItemProperty -Path `$regKey -Name ProxyServer -Value "`${proxyHost}:`${httpPort}"
}
Function Reset-Proxy() {
    Remove-Item -Path Env:\http_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\https_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\ftp_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\all_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\HTTP_PROXY -ErrorAction:Ignore
    Remove-Item -Path Env:\HTTPS_PROXY -ErrorAction:Ignore
    Remove-Item -Path Env:\FTP_PROXY -ErrorAction:Ignore
    Remove-Item -Path Env:\ALL_PROXY -ErrorAction:Ignore
    [Environment]::SetEnvironmentVariable('http_proxy', `$null, 'User')
    [Environment]::SetEnvironmentVariable('https_proxy', `$null, 'User')
    [Environment]::SetEnvironmentVariable('ftp_proxy', `$null, 'User')
    [Environment]::SetEnvironmentVariable('all_proxy', `$null, 'User')

    `$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path `$regKey -Name ProxyEnable -Value 0
    Set-ItemProperty -Path `$regKey -Name ProxyServer -Value ""
}
"@ | Set-Content -Path $PROFILE.CurrentUserAllHosts -Encoding utf8

Update-SessionEnvironment
& $PROFILE.CurrentUserAllHosts

# Install Chocolatey packages
choco install vim --params="'/InstallDir:$Env:ChocolateyToolsLocation\Vim /NoDesktopShortcuts'" --yes
choco install python3 --params="'/InstallDir:$Env:ChocolateyToolsLocation\Python3'" --yes
choco install cmake --installargs="'ADD_CMAKE_TO_PATH=System'" --yes
choco install vscode conemu mobaxterm vcxsrv --yes
choco install fzf bat ripgrep shellcheck wget mingw --yes

# Setup Vim
New-Item -Path "~\vimfiles\autoload" -Type Directory -Force
(New-Object -TypeName System.Net.WebClient).DownloadFile(
    'https://github.com/junegunn/vim-plug/raw/master/plug.vim',
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
let g:NERDTreeNotificationThreshold = 200
let g:NERDTreeAutoToggleEnabled = (!&diff && argc() > 0)
let s:NERDTreeClosedByResizing = 1
function s:NERDTreeAutoToggle(minbufwidth = 80)
    if g:NERDTreeAutoToggleEnabled && !(exists('b:NERDTree') && b:NERDTree.isTabTree())
        let NERDTreeIsOpen = (g:NERDTree.ExistsForTab() && g:NERDTree.IsOpen())
        let width = winwidth('%')
        let numberwidth = ((&number || &relativenumber) ? max([&numberwidth, strlen(line('`$')) + 1]) : 0)
        let signwidth = ((&signcolumn == 'yes' || &signcolumn == 'auto') ? 2 : 0)
        let foldwidth = &foldcolumn
        let bufwidth = width - numberwidth - foldwidth - signwidth
        if bufwidth >= a:minbufwidth + (g:NERDTreeWinSize + 1) * (1 - NERDTreeIsOpen)
            if !NERDTreeIsOpen && s:NERDTreeClosedByResizing
                if str2nr(system('dir /b "' . getcwd() . '" | find /v /c ""')) <= g:NERDTreeNotificationThreshold
                    NERDTree
                    wincmd p
                    let s:NERDTreeClosedByResizing = 0
                endif
            endif
        elseif NERDTreeIsOpen && !s:NERDTreeClosedByResizing
            NERDTreeClose
            let s:NERDTreeClosedByResizing = 1
        endif
    endif
endfunction
autocmd VimEnter,VimResized * call s:NERDTreeAutoToggle(80)
autocmd BufEnter * if winnr('`$') == 1 && (exists('b:NERDTree') && b:NERDTree.isTabTree()) | quit | endif

let g:airline#extensions#tabline#enabled = 1

let g:bufferline_echo = 0

let g:undotree_WindowLayout = 3

if &diff
    let &diffexpr = 'EnhancedDiff#Diff("git diff", "--diff-algorithm=histogram")'
endif
let g:DirDiffExcludes = ".git,.svn,.hg,CVS,.idea,.*.swp,*.pyc,__pycache__"
autocmd VimResized * if &diff | wincmd = | endif

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

let g:ycm_cache_omnifunc = 1
let g:ycm_seed_identifiers_with_syntax = 1
let g:ycm_complete_in_comments = 1
let g:ycm_complete_in_strings = 1
let g:ycm_collect_identifiers_from_tags_files = 1
let g:ycm_collect_identifiers_from_comments_and_strings = 0
autocmd InsertLeave * if pumvisible() | pclose | endif
inoremap <expr> <CR>       pumvisible() ? "\<C-y>\<Esc>a" : "\<CR>"
inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
inoremap <expr> <PageDown> pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
inoremap <expr> <PageUp>   pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<PageUp>"
let g:ycm_key_list_stop_completion = ['<C-y>']
let g:ycm_key_list_select_completion = ['<Down>']
let g:ycm_key_list_previous_completion = ['<Up>']

let g:tex_flavor = 'latex'

if !exists('`$SSH_CONNECTION')
    let g:mkdp_auto_start = 1
endif

call plug#begin('~/vimfiles/plugged')
    Plug 'flazz/vim-colorschemes'
    Plug 'mhinz/vim-startify'
    Plug 'scrooloose/nerdtree'
    Plug 'scrooloose/nerdcommenter'
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
    Plug 'ryanoasis/vim-devicons'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'bling/vim-bufferline'
    Plug 'chrisbra/vim-diff-enhanced'
    Plug 'will133/vim-dirdiff'
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
    Plug 'codota/tabnine-vim'
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
