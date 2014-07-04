" ----------------------------------------------------------------------------------------
" Base settings
" ----------------------------------------------------------------------------------------
set nocompatible           " vi との互換性をオフにする。オフにする事により、vim の機能が使えるようなる
set encoding=utf8          " エンコーディング設定
set fileencoding=utf-8     " カレントバッファ内のファイルの文字エンコーディングを設定する
set clipboard=unnamed      " OSのクリップボードを使用する

" ヘルプを出さない
nmap <F1> <nop>
imap <F1> <nop>

" search
" ----------------------
set ignorecase
set smartcase
set wrapscan
set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc> " Esc 連打すると検索結果のハイライトが消える
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz

" ----------------------------------------------------------------------------------------
" Move 
" ----------------------------------------------------------------------------------------
imap <c-e> <END>
imap <c-a> <HOME>
imap <c-h> <LEFT>
imap <c-j> <DOWN>
imap <c-k> <UP>
imap <c-l> <Right>

" brackets
" --------------------
inoremap {} {}<LEFT>
inoremap [] []<LEFT>
inoremap () ()<LEFT>
inoremap "" ""<LEFT>
inoremap '' ''<LEFT>
inoremap <> <><LEFT>
inoremap []5 [% %]<LEFT><LEFT><LEFT>

" ----------------------------------------------------------------------------------------
" appearance
" ----------------------------------------------------------------------------------------
set number
set ruler 

colorscheme molokai
syntax on
let g:molokai_original = 1
let g:rehash256 = 1
set background=dark

" タブ、空白、改行を可視化
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

" ----------------------------------------------------------------------------------------
" appearance (Only GUI)
" ----------------------------------------------------------------------------------------

if has('gui_macvim')
  " .gvimrc http://rhysd.hatenablog.com/entry/20111113/1321193061
  set transparency=0 " initialize
  nnoremap <expr><F12> &transparency+20 >= 100 ? ":set transparency=0\<CR>" : ":let &transparency=&transparency+20\<CR>"
  " colorscheme desert
endif

" ----------------------------------------------------------------------------------------
" Anywhere SID http://qiita.com/wadako111/items/755e753677dd72d8036d
" ----------------------------------------------------------------------------------------
function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID_PREFIX$')
endfunction

" Set tabline.
function! s:my_tabline()  "{{{
  let s = ''
  for i in range(1, tabpagenr('$'))
    let bufnrs = tabpagebuflist(i)
    let bufnr = bufnrs[tabpagewinnr(i) - 1]  " first window, first appears
    let no = i  " display 0-origin tabpagenr.
    let mod = getbufvar(bufnr, '&modified') ? '!' : ' '
    let title = fnamemodify(bufname(bufnr), ':t')
    let title = '[' . title . ']'
    let s .= '%'.i.'T'
    let s .= '%#' . (i == tabpagenr() ? 'TabLineSel' : 'TabLine') . '#'
    let s .= no . ':' . title
    let s .= mod
    let s .= '%#TabLineFill# '
  endfor
  let s .= '%#TabLineFill#%T%=%#TabLine#'
  return s
endfunction "}}}
let &tabline = '%!'. s:SID_PREFIX() . 'my_tabline()'
set showtabline=2 " 常にタブラインを表示

" The prefix key.
nnoremap    [Tag]   <Nop>
nmap    t [Tag]
" Tab jump
for n in range(1, 9)
  execute 'nnoremap <silent> [Tag]'.n  ':<C-u>tabnext'.n.'<CR>'
endfor
" t1 で1番左のタブ、t2 で1番左から2番目のタブにジャンプ

map <silent> [Tag]c :tablast <bar> tabnew<CR>
" tc 新しいタブを一番右に作る
map <silent> [Tag]x :tabclose<CR>
" tx タブを閉じる
map <silent> [Tag]n :tabnext<CR>
" tn 次のタブ
map <silent> [Tag]p :tabprevious<CR>
" tp 前のタブ


" ----------------------------------------------------------------------------------------
" neobundle
" ----------------------------------------------------------------------------------------
set nocompatible               " Be iMproved

if has('vim_starting')
set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#rc(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'

" Recommended to install
" After install, turn shell ~/.vim/bundle/vimproc, (n,g)make -f your_machines_makefile
NeoBundle 'Shougo/vimproc', {
        \ 'build' : {
                \ 'windows' : 'make -f make_mingw32.mak',
                \ 'cygwin' : 'make -f make_cygwin.mak',
                \ 'mac' : 'make -f make_mac.mak',
                \ 'unix' : 'make -f make_unix.mak',
        \ },
\ }

filetype plugin indent on     " Required!

" Brief help
" :NeoBundleList          - list configured bundles
" :NeoBundleInstall(!)    - install(update) bundles
" :NeoBundleClean(!)      - confirm(or auto-approve) removal of unused bundles

" Installation check.
NeoBundleCheck

NeoBundle 'Shougo/neocomplcache'
" NeoBundle 'Shougo/neosnippet'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'thinca/vim-quickrun'
NeoBundle 'davidoc/taskpaper.vim'
NeoBundle 'itchyny/lightline.vim'
NeoBundle 'altercation/vim-colors-solarized'
NeoBundle 'mattn/gist-vim'
NeoBundle 'mattn/webapi-vim'

" ----------------------------------------------------------------------------------------↲
"  gist-vim
"  ----------------------------------------------------------------------------------------↲
let g:gist_api_url = 'http://ghe.tokyo.pb/api/v3'
