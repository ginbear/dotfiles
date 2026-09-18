set mouse=

" ========== 基本設定 ==========
" 行番号
set number
set relativenumber

" インデント
set expandtab
set tabstop=2
set shiftwidth=2
set autoindent
set smartindent

" 検索
set ignorecase
set smartcase
set incsearch
set hlsearch

" 表示
set cursorline
set scrolloff=8
set signcolumn=yes
set termguicolors

" その他
set hidden
set nobackup
set noswapfile
set undofile
set updatetime=300
set clipboard=unnamedplus

" ========== キーマップ ==========
let mapleader = " "

" 検索ハイライト解除
nnoremap <Esc> :nohlsearch<CR>

" ウィンドウ移動
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" ========== プラグイン (lazy.nvim) ==========
lua require('plugins')
