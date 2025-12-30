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
winget source update
winget install Git.Git Git.MinGit GitHub.cli --scope=machine
winget install JanDeDobbeleer.OhMyPosh --scope=machine
winget install Microsoft.VisualStudioCode --scope=machine
winget install Microsoft.WindowsTerminal --scope=machine

# Setup PowerShell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name posh-git -AcceptLicense -Force -Confirm:$false
Install-Module -Name PSReadLine -SkipPublisherCheck -AcceptLicense -Force -Confirm:$false
Install-Module -Name Get-ChildItemColor -AllowClobber -AcceptLicense -Force -Confirm:$false
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "${Env:ProgramFiles}\PowerShell\7\pwsh.exe" -PropertyType String -Force

if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
    New-Item -Path $PROFILE.CurrentUserAllHosts -Type File -Force
}
@"
chcp 65001

Import-Module -Name PSReadLine -Force -ErrorAction:Ignore
Import-Module -Name posh-git -ErrorAction:Ignore

if (Test-Path -Path "~\Miniconda3\shell\condabin\conda-hook.ps1") {
    & "~\Miniconda3\shell\condabin\conda-hook.ps1"
}

`$Env:YAZI_FILE_ONE = "`${Env:ProgramFiles}\Git\usr\bin\file.exe"
oh-my-posh init pwsh --config "ys" | Invoke-Expression
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function Complete

Set-Alias -Name which -Value Get-Command -Option AllScope
if (Get-Command -Name eza -ErrorAction SilentlyContinue) {
    Function Get-ChildItemEza {
        eza --header --group-directories-first --group --binary ``
            --time-style="+%Y-%m-%d %H:%M:%S" ``
            --color=auto --classify=auto --icons=auto --git ``
            `$Args
    }
    Function Get-ChildItemEzaAll {
        Get-ChildItemEza -A
    }
    Function Get-ChildItemEzaLong {
        Get-ChildItemEza -lh
    }
    Function Get-ChildItemEzaAllLong {
        Get-ChildItemEza -Alh
    }
    Set-Alias -Name ls -Value Get-ChildItemEza -Option AllScope
    Set-Alias -Name la -Value Get-ChildItemEzaAll -Option AllScope
    Set-Alias -Name ll -Value Get-ChildItemEzaLong -Option AllScope
    Set-Alias -Name l -Value Get-ChildItemEzaAllLong -Option AllScope
} else {
    Import-Module -Name Get-ChildItemColor -ErrorAction:Ignore
    Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope
    Set-Alias -Name ll -Value Get-ChildItemColor -Option AllScope
}

Function Set-Proxy {
    Param(
        [string]`$ProxyHost = "127.0.0.1",
        [int]`$HttpPort = 7890,
        [int]`$HttpsPort = 7890,
        [int]`$FtpPort = 7890,
        [int]`$SocksPort = 7891,
        [switch]`$ProcessOnly = `$false
    )
    `$Env:http_proxy = "http://`${ProxyHost}:`${HttpPort}"
    `$Env:https_proxy = "http://`${ProxyHost}:`${HttpsPort}"
    `$Env:ftp_proxy = "http://`${ProxyHost}:`${FtpPort}"
    `$Env:all_proxy = "socks5://`${ProxyHost}:`${SocksPort}"
    if (`$ProcessOnly) {
        return
    }

    [Environment]::SetEnvironmentVariable('http_proxy', "http://`${ProxyHost}:`${HttpPort}", 'User')
    [Environment]::SetEnvironmentVariable('https_proxy', "http://`${ProxyHost}:`${HttpsPort}", 'User')
    [Environment]::SetEnvironmentVariable('ftp_proxy', "http://`${ProxyHost}:`${FtpPort}", 'User')
    [Environment]::SetEnvironmentVariable('all_proxy', "socks5://`${ProxyHost}:`${SocksPort}", 'User')

    `$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path `$regKey -Name ProxyEnable -Value 1
    Set-ItemProperty -Path `$regKey -Name ProxyServer -Value "`${ProxyHost}:`${HttpPort}"
}
Function Reset-Proxy {
    Remove-Item -Path Env:\http_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\https_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\ftp_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\all_proxy -ErrorAction:Ignore
    [Environment]::SetEnvironmentVariable('http_proxy', `$null, 'User')
    [Environment]::SetEnvironmentVariable('https_proxy', `$null, 'User')
    [Environment]::SetEnvironmentVariable('ftp_proxy', `$null, 'User')
    [Environment]::SetEnvironmentVariable('all_proxy', `$null, 'User')

    `$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path `$regKey -Name ProxyEnable -Value 0
    Set-ItemProperty -Path `$regKey -Name ProxyServer -Value ""
}
"@ | Set-Content -Path $PROFILE.CurrentUserAllHosts -Encoding utf8

# Install Chocolatey packages
winget install Python.Python.3.14 --scope=machine
choco install cmake --installargs="'ADD_CMAKE_TO_PATH=System'" --yes
choco install vim --params="'/InstallDir:${Env:ChocolateyToolsLocation}\Vim /NoDesktopShortcuts'" --yes
choco install fzf bat ripgrep yazi eza shellcheck wget mingw --yes

# Setup Vim
New-Item -Path "~\vimfiles\autoload" -Type Directory -Force
(New-Object -TypeName System.Net.WebClient).DownloadFile(
    'https://github.com/junegunn/vim-plug/raw/HEAD/plug.vim',
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
set nowrap
set whichwrap=b,s,<,>,[,]
set showmatch
set hlsearch
execute 'nohlsearch'
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
set guifont=DejaVuSansM\ Nerd\ Font\ Mono:h12
colorscheme desert
source `$VIMRUNTIME/delmenu.vim
source `$VIMRUNTIME/menu.vim

if has('mouse')
    set mouse=a
endif
if &term =~ 'xterm'
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_SR = "\<Esc>]50;CursorShape=2\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

autocmd GUIEnter * set lines=50 columns=160

autocmd GUIEnter * set spell spelllang=en_us

autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("`$") | execute "normal! g'\"" | endif
autocmd BufWritePre,FileWritePre * RemoveTrailingSpaces

let g:tex_flavor = 'latex'
autocmd Filetype sh,zsh,gitconfig,c,cpp,make,go set noexpandtab
autocmd Filetype text,markdown,rst,asciidoc,tex set wrap
autocmd FileType vim,tex let b:autoformat_autoindent = 0
autocmd FileType gitcommit set colorcolumn=50,72,80,100,120,140

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
function s:NERDTreeAutoToggle(minbufwidth)
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

call plug#begin('~/vimfiles/plugged')
    Plug 'flazz/vim-colorschemes'
    Plug 'mhinz/vim-startify'
    Plug 'preservim/nerdtree'
    Plug 'preservim/nerdcommenter'
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
    Plug 'ryanoasis/vim-devicons'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'bling/vim-bufferline'
    Plug 'chrisbra/vim-diff-enhanced'
    Plug 'will133/vim-dirdiff'
    Plug 'yggdroot/indentline'
    Plug 'editorconfig/editorconfig-vim'
    Plug 'luochen1990/rainbow'
    Plug 'jaxbot/semantic-highlight.vim'
    Plug 'chrisbra/Colorizer'
    Plug 'jiangmiao/auto-pairs'
    Plug 'tpope/vim-surround'
    Plug 'mg979/vim-visual-multi'
    Plug 'tpope/vim-unimpaired'
    Plug 'tpope/vim-endwise'
    Plug 'mbbill/undotree'
    Plug 'airblade/vim-gitgutter'
    Plug 'tpope/vim-fugitive'
    Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim'
    Plug 'vim-autoformat/vim-autoformat'
    Plug 'vim-syntastic/syntastic'
    Plug 'github/copilot.vim'
    Plug 'honza/vim-snippets'
    Plug 'PProvost/vim-ps1'
    Plug 'elzr/vim-json'
    Plug 'godlygeek/tabular'
    Plug 'plasticboy/vim-markdown'
    Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }
    Plug 'lervag/vimtex'
call plug#end()
"@ | Set-Content -Path ~\_vimrc -Encoding utf8

vim -c "PlugInstall | PlugUpgrade | PlugUpdate | sleep 5 | quitall"
