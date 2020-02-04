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
set tabstop=4
set shiftwidth=4
set list
set listchars=tab:▸\ ,trail:·
set number
set ruler
set colorcolumn=80,100,120,140
set cursorline
set foldenable
set foldmethod=indent
set foldlevel=3
set scrolloff=3
set sidescroll=5
set wrap
set showmatch
set hlsearch
set incsearch
" set spell spelllang=en_us
set autochdir
set visualbell
set autoread
set showcmd
set wildmenu
set wildmode=longest:list,full
set background=dark
set t_Co=256
set guifont=DejaVuSansMonoNerdFontComplete-Book:h14
set linespace=2
colorscheme monokai


autocmd GUIEnter * set lines=42 columns=160

autocmd BufWritePre,FileWritePre * RemoveTrailingSpaces
autocmd Filetype python set expandtab
autocmd FileType vim,tex let b:autoformat_autoindent = 0

let g:NERDChristmasTree = 1
let g:NERDTreeMouseMode = 2
let g:NERDTreeShowBookmarks = 1
let g:NERDTreeShowFiles = 1
let g:NERDTreeShowHidden = 1
let g:NERDTreeShowLineNumbers = 0
let g:NERDTreeWinPos = 'left'
let g:NERDTreeWinSize = 31
autocmd VimEnter * if str2nr(system("ls -l $PWD | wc -l")) <= 1000 |
                 \     let width = winwidth('%') |
                 \     let numberwidth = ((&number || &relativenumber)? max([&numberwidth, strlen(line('$')) + 1]) : 0) |
                 \     let signwidth = ((&signcolumn == 'yes' || &signcolumn == 'auto')? 2 : 0) |
                 \     let foldwidth = &foldcolumn |
                 \     let bufwidth = width - numberwidth - foldwidth - signwidth |
                 \     if bufwidth > 80 + NERDTreeWinSize |
                 \         NERDTree |
                 \         wincmd p |
                 \     endif |
                 \     unlet width numberwidth signwidth foldwidth bufwidth |
                 \ endif
autocmd BufEnter * if (winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree()) |
                 \ q |
                 \ endif

let g:rainbow_active = 1

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_loc_list_height = 5
let g:syntastic_check_on_wq = 0
autocmd GUIEnter * let g:syntastic_check_on_open = 1

let g:mkdp_auto_start = 1

call plug#begin('~/.vim/plugged')
    Plug 'scrooloose/nerdtree'
    Plug 'scrooloose/nerdcommenter'
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'ryanoasis/vim-devicons'
    Plug 'yggdroot/indentline'
    Plug 'jiangmiao/auto-pairs'
    Plug 'airblade/vim-gitgutter'
    Plug 'tpope/vim-fugitive'
    Plug 'luochen1990/rainbow'
    Plug 'Chiel92/vim-autoformat'
    Plug 'vim-syntastic/syntastic'
    Plug 'godlygeek/tabular'
    Plug 'plasticboy/vim-markdown'
    Plug 'iamcco/markdown-preview.nvim'
call plug#end()
