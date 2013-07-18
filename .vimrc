" --------------------------------------------------------------------------------
" set standard option
" --------------------------------------------------------------------------------
set nocompatible           " vi との互換性をオフにする。オフにする事により、vim の機能が使えるようなる
set encoding=utf8          " エンコーディング設定
set fileencoding=utf-8     " カレントバッファ内のファイルの文字エンコーディングを設定する
set vb t_vb=               " ビープ音を鳴らさない
set clipboard=unnamed      " OSのクリップボードを使用する
set textwidth=0            " 自動改行をしない
set clipboard=unnamed,autoselect

" display
" ----------------------
set number                 " 左側に行数を表示
set ruler                  " カーソルが何行目の何列目に置かれているかを表示する
set list                   " タブ文字、行末など不可視文字を表示する
set formatoptions=q        " 自動改行をしない
set wrap                   " 画面右端で折り返し
set title
set wildmenu
set showcmd
set linespace=0
set textwidth=78
set scrolloff=5            " カーソルの上または下に表示する最小限の行数
set cmdheight=2
set laststatus=2
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P
set cursorline
set cursorcolumn
" highlight LineNr ctermfg=255 ctermbg=54     " 行数の文字色と背景色
" highlight StatusLine ctermfg=23 ctermbg=0    " ステータスバーの文字色と背景色

" syntax color
" ---------------------
syntax on
set t_Co=256
let g:hybrid_use_Xresources = 1
colorscheme jellybeans
" colorscheme lucius
" LuciusLight

" search
" ----------------------
set ignorecase
set smartcase
set wrapscan
set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc> " Esc 連打すると検索結果のハイライトが消える

" edit
" ---------------------
set autoindent
set cindent
set showmatch
set pastetoggle=<F12>

" tab
" --------------------
set tabstop=4
set expandtab
set smarttab
set shiftwidth=4
set shiftround

" keymap
" --------------------
set bioskey
set timeout
set timeoutlen=500

" backup
" --------------------
set backup
set backupdir=~/.vim_backup
let &directory = &backupdir

" backspace とかカーソルキーとか
" --------------------
set backspace=indent,eol,start
" set whichwrap=b,s,h,l,<,>,[,]  "カーソルを行頭，行末で止まらないようにする
" Ctrl + v ↑  入力してる
" imap A <Up>
" imap B <Down>
" imap C <Right>
" imap D <Left>

" --------------------------------------------------------------------------------
" normal mode settings
" --------------------------------------------------------------------------------
" Prefix-key
" ----------------------
nnoremap [Prefix] <nop>
nmap <space> [Prefix]

" window
" 画面入れ替え Ctrl w + x
" --------------------
nnoremap <silent> [Prefix]1 :only<CR>
nnoremap <silent> [Prefix]2 :sp<CR>
nnoremap <silent> [Prefix]3 :vsp<CR>

" buffer
" Ctrl+w j|k|w|p で移動
" --------------------
nnoremap <silent> [Prefix]l :ls<CR>:b    " バッファのリストを出す
nnoremap <silent> [Prefix]p :bp<CR>      " バッファを戻る
nnoremap <silent> [Prefix]n :bn<CR>      " バッファを進む
nnoremap <silent> [Prefix]d :bd<CR>      " バッファを閉じる
nnoremap <silent> [Prefix]o <C-W>o       " カーソルのあるウインドウを最大化する(カレント以外のウインドウを閉 じる)
nnoremap <silent> [Prefix]h :hide<CR>    " カーソルのあるウインドウを隠す

" general
" --------------------
nnoremap <silent> [Prefix]e :Explore<CR>               " ファイラーを起動
nnoremap <silent> [Prefix]s :<C-u>update<CR>           " ファイル保存：バッファ変更時のみ保存
nnoremap          [Prefix]. :<C-u>edit $MYVIMRC<CR>    " .vimrcを開く
nnoremap          [Prefix], :<C-u>source $MYVIMRC<CR>  " source ~/.vimrc を実行する。

" search
" --------------------
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz

" Other
" --------------------
" inoremap <c-j> <esc>     " nomarl mode に戻るときに Ctrl + j でいける。これになれると怖いから無効にしておく
" vnoremap <c-j> <esc>

" --------------------------------------------------------------------------------
" insert mode settings
" --------------------------------------------------------------------------------
" move
" --------------------
inoremap <C-a> <Home>
inoremap <C-e> <End>
" inoremap <C-h> <Left>  " backspace での削除と競合する
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-l> <Right>

" texu-edit
" --------------------
inoremap <C-d> <Del>
" noremap <CR> i<CR><ESC>

" brackets
" --------------------
inoremap {} {}<LEFT>
inoremap [] []<LEFT>
inoremap () ()<LEFT>
inoremap "" ""<LEFT>
inoremap '' ''<LEFT>
inoremap <> <><LEFT>
inoremap []5 [% %]<LEFT><LEFT><LEFT>

" date/time
" insert mode -> C-D C-D で時間挿入
" --------------------
imap <silent> <C-D><C-D> <C-R>=strftime('%Y/%m/%d %H:%M:%S')<CR>

"挿入モード時、ステータスラインの色を変更
" powerline で制御できてるのでコメントアウトする
" --------------------
" let g:hi_insert = 'highlight StatusLine guifg=darkblue guibg=darkyellow gui=none ctermfg=255 ctermbg=196 cterm=none'
" 
" if has('syntax')
"   augroup InsertHook
"     autocmd!
"     autocmd InsertEnter * call s:StatusLine('Enter')
"     autocmd InsertLeave * call s:StatusLine('Leave')
"   augroup END
" endif
" 
" let s:slhlcmd = ''
" function! s:StatusLine(mode)
"   if a:mode == 'Enter'
"     silent! let s:slhlcmd = 'highlight ' . s:GetHighlight('StatusLine')
"     silent exec g:hi_insert
"   else
"     highlight clear StatusLine
"     silent exec s:slhlcmd
"   endif
" endfunction
" 
" function! s:GetHighlight(hi)
"   redir => hl
"   exec 'highlight '.a:hi
"   redir END
"   let hl = substitute(hl, '[\r\n]', '', 'g')
"   let hl = substitute(hl, 'xxx', '', '')
"   return hl
" endfunction
" 
" if has('unix') && !has('gui_running')
"   " ESC後にすぐ反映されない対策
"   inoremap <silent> <ESC> <ESC>
" endif

" タブを使う
" http://qiita.com/wadako111@github/items/755e753677dd72d8036d
" Anywhere SID.
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


" NeoBundle設定
" https://github.com/Shougo/neobundle.vim
" インストール
" $ mkdir -p ~/.vim/bundle
" $ export GIT_SSL_NO_VERIFY=true
" $ git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
" :NeoBundleInstall でプラグインインストール :NeoBundleInstall! で更新
" --------------------$
filetype plugin indent off     " required!
if has('vim_starting')
  set runtimepath+=~/.vim/bundle/neobundle.vim/
  call neobundle#rc(expand('~/.vim/bundle/'))
endif

let g:neobundle_default_git_protocol='https' " defalt は git を使用する。必要に応じて設定

" gitを使ったプラグインマネージャ 基本Vundleと一緒
NeoBundle 'Shougo/neobundle.vim'

NeoBundle 'The-NERD-tree'
" NERDTree
" http://kokukuma.blogspot.jp/2012/03/vim-nerdtree.html
" 引数なしで実行したとき、NERDTreeを実行する
" --------------------$
nmap <silent> <C-e>      :NERDTreeToggle<CR>
vmap <silent> <C-e> <Esc>:NERDTreeToggle<CR>
omap <silent> <C-e>      :NERDTreeToggle<CR>
imap <silent> <C-e> <Esc>:NERDTreeToggle<CR>
cmap <silent> <C-e> <C-u>:NERDTreeToggle<CR>
autocmd vimenter * if !argc() | NERDTree | endif " 引数なしでvimを開いたらNERDTreeを起動、 "引数ありならNERDTreeは起動しない、引数で渡されたファイルを開く。
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif " 他のバッファをすべて閉じた時にNERDTreeが開いていたらNERDTreeも一緒に閉じる

filetype plugin indent on

" NeoBundle 'git://github.com/Lokaltog/vim-powerline.git'
NeoBundle 'git://github.com/Lokaltog/vim-powerline.git'

