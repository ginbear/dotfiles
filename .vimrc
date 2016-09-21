" Vim tips
"
" ggVG   全選択
" =      インデント整理
" ci"    "" で囲まれた中身を消してインサート, ci' だったら '' でもいける
" ciw    カーソル上の単語を消してインサート
" cit    HTMLタグもいける
" ea     単語の後にインサート
" s/S    カーソル上/カーソル行を消してインサート
" g;     直前の変更箇所にジャンプ, g, で戻る
"
" ----------------------------------------------------------------------------------------
" Base settings
" ----------------------------------------------------------------------------------------
set nocompatible           " vi との互換性をオフにする。オフにする事により、vim の機能が使えるようなる
set encoding=utf8          " エンコーディング設定
set fileencoding=utf-8     " カレントバッファ内のファイルの文字エンコーディングを設定する
set clipboard=unnamed      " OSのクリップボードを使用する
set nobackup
set noundofile             " *.un~ なファイルを作らない
set expandtab
set tabstop=2
set scrolloff=5            " スクロール時の前後行数
set cursorline             " カーソルがある行がハイライト
nmap <F1> <nop>            " help を出さない
imap <F1> <nop>            " help を出さない

" より便利に使う
" ----------------------
inoremap <silent> jj <ESC> " インサートモードから jj でコマンドモードへ戻る

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

" filetype
" ----------------------
au BufNewFile,BufRead *.pp setf puppet

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
" Anywhere SID http://qiita.com/wadako111/items/755e753677dd72d8036d
" tab を便利に使うやつ
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
" install
" $ mkdir -p ~/.vim/bundle && git clone git://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
" $ curl https://raw.githubusercontent.com/Shougo/neobundle.vim/master/bin/install.sh | sh
" ----------------------------------------------------------------------------------------

" Note: Skip initialization for vim-tiny or vim-small.
if !1 | finish | endif

if has('vim_starting')
  if &compatible
    set nocompatible               " Be iMproved
  endif

  " Required:
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

" Required:
call neobundle#begin(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

" My Bundles here:
" Refer to |:NeoBundle-examples|.
" Note: You don't set neobundle setting in .gvimrc!

NeoBundle 'Shougo/neocomplcache'            " snippet
NeoBundle 'Shougo/neosnippet'               " snippet
NeoBundle 'Shougo/neosnippet-snippets'      " snippet
NeoBundle 'Shougo/neomru.vim'
NeoBundle 'Shougo/unite.vim'                " unite filer
NeoBundle 'ujihisa/unite-colorscheme'       " unite filer colorscheme
NeoBundle 'itchyny/lightline.vim'
NeoBundle 'Puppet-Syntax-Highlighting'
NeoBundle 'glidenote/serverspec-snippets'
NeoBundle 'scrooloose/syntastic'            " syntax check
NeoBundle 'mattn/gist-vim'                  " gist
NeoBundle 'mattn/webapi-vim'                " gist
NeoBundle 'airblade/vim-gitgutter'          " git の差分が見える
NeoBundle 'jeffreyiacono/vim-colors-wombat' " color
NeoBundle 'nanotech/jellybeans.vim'         " color
NeoBundle 'tomasr/molokai'                  " color
NeoBundle 'sjl/badwolf'                     " color

call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck

"----------------------------------------------------------------------------------------↲
" neosnippet
"----------------------------------------------------------------------------------------↲
" Plugin key-mappings.
imap <C-k> <Plug>(neosnippet_expand_or_jump)
smap <C-k> <Plug>(neosnippet_expand_or_jump)
xmap <C-k> <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)"
\: pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)"
\: "\<TAB>"

" For conceal markers.
if has('conceal')
  set conceallevel=2 concealcursor=niv
endif

let g:neocomplcache_enable_at_startup = 1 " 自動起動
let g:neosnippet#snippets_directory = [
      \'~/.vim/bundle/serverspec-snippets',
      \'~/.vim/bundle/neosnippet-snippets/neosnippets',
      \]

"----------------------------------------------------------------------------------------↲
" Unite
"----------------------------------------------------------------------------------------↲
" 入力モードで開始する
" let g:unite_enable_start_insert=1
" バッファ一覧
nnoremap <silent> ,ub :<C-u>Unite buffer<CR>
" ファイル一覧
nnoremap <silent> ,uf :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
" レジスタ一覧
nnoremap <silent> ,ur :<C-u>Unite -buffer-name=register register<CR>
" 最近使用したファイル一覧
nnoremap <silent> ,um :<C-u>Unite file_mru<CR>
" 常用セット
nnoremap <silent> ,uu :<C-u>Unite buffer file_mru<CR>
" 全部乗せ
nnoremap <silent> ,ua :<C-u>UniteWithBufferDir -buffer-name=files buffer file_mru bookmark file<CR>
" ウィンドウを分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
au FileType unite inoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
" ウィンドウを縦に分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
au FileType unite inoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')

"----------------------------------------------------------------------------------------↲
" syntastic
"----------------------------------------------------------------------------------------↲
let g:syntastic_puppet_puppetlint_args="--no-80chars-check --no-documentation-check --no-unquoted_file_mode-check --no-file_mode-check"

"----------------------------------------------------------------------------------------↲
" lightline
"----------------------------------------------------------------------------------------↲
set laststatus=2
" source ~/.vim/lightline.conf

"----------------------------------------------------------------------------------------↲
" vim-gitgutter
"----------------------------------------------------------------------------------------↲
nnoremap <silent> ,gg :<C-u>GitGutterToggle<CR>
nnoremap <silent> ,gh :<C-u>GitGutterLineHighlightsToggle<CR>

"----------------------------------------------------------------------------------------↲
" gist-vim
"----------------------------------------------------------------------------------------↲
let g:gist_api_url = 'https://git.pepabo.com/api/v3'

" ----------------------------------------------------------------------------------------
" appearance (colorscheme で bundle 利用のものがあるので、下部に設置している)
" ----------------------------------------------------------------------------------------
set number
set ruler 
syntax on

" mkdir ~/.vim/colors ; cd ~/.vim/colors
" git clone https://github.com/tomasr/molokai
" mv molokai/colors/molokai.vim ~/.vim/colors/
" let g:molokai_original = 1
colorscheme badwolf
set t_Co=256
set background=dark

" タブ、空白、改行を可視化
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

" カーソル行を強調表示しない
set nocursorline
" 挿入モードの時のみ、カーソル行をハイライトする
autocmd InsertEnter,InsertLeave * set cursorline!

" iTerm2 でコンソールの形状を変える
let &t_SI = "\e]50;CursorShape=1\x7"
let &t_EI = "\e]50;CursorShape=0\x7"

" ----------------------------------------------------------------------------------------
" appearance (Only GUI)
" ----------------------------------------------------------------------------------------

if has('gui_macvim')
  " .gvimrc http://rhysd.hatenablog.com/entry/20111113/1321193061
  set transparency=0 " initialize
  nnoremap <expr><F12> &transparency+20 >= 100 ? ":set transparency=0\<CR>" : ":let &transparency=&transparency+20\<CR>"
endif

