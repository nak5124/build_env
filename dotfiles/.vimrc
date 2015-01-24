" vim:set ts=4 sts=4 sw=4 expandtab:
set nocompatible
set modeline
" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencoding=utf-8
set fileencodings=utf-8,iso-2022-jp,cp932,euc-jp,ucs-2,sjis,default,latin
set fileformat=unix

" Neobundle
filetype off

if has('vim_starting')
  set runtimepath+=$HOME/.vim/bundle/neobundle.vim
  call neobundle#begin(expand('$HOME/.vim/bundle/'))
  NeoBundleFetch 'Shougo/neobundle.vim'
  call neobundle#end()
endif

NeoBundle 'Shougo/neobundle.vim'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/vimproc'
NeoBundle 'Shougo/vimshell'
NeoBundle 'Shougo/vimfiler'
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'itchyny/lightline.vim'
NeoBundle 't9md/vim-textmanip'
NeoBundle 'ujihisa/unite-colorscheme'
NeoBundle 'tomasr/molokai'
NeoBundle 'tomtom/tcomment_vim'
NeoBundle 'Townk/vim-autoclose'
NeoBundle 'grep.vim'
NeoBundle 'drillbits/nyan-modoki.vim'

NeoBundleCheck

" vimshell
let g:vimshell_prompt_expr = 'getcwd()." > "'
let g:vimshell_prompt_pattern = '^\f\+ > '
nnoremap <silent> vs :VimShell<CR>
nnoremap <silent> vsc :VimShellCreate<CR>
nnoremap <silent> vp :VimShellPop<CR>

" scheme
set t_ut=
set t_Co=256
set t_Sf=[3%dm
set t_Sb=[4%dm
set background=dark
let g:molokai_original = 0
let g:rehash256 = 1
colorscheme molokai
syntax on
let g:is_bash = 1
filetype plugin indent on
set foldmethod=syntax
" tabs
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set smartindent
set smarttab
set showtabline=2
" show line number
set number
" highlight cursor line&column
augroup cch
    autocmd! cch
    autocmd WinLeave * set nocursorline
    autocmd WinLeave * set nocursorcolumn
    autocmd WinEnter,BufRead * set cursorline
    autocmd WinEnter,BufRead * set cursorcolumn
augroup END
" always show status line
set laststatus=2
"set statusline=%F%m%r%h%w[%{&ff}]%=%{g:NyanModoki()}(%l,%c)[%P]
"let g:nyan_modoki_select_cat_face_number = 2
"let g:nayn_modoki_animation_enabled= 1
let g:lightline = {
        \ 'colorscheme': 'wombat',
        \ 'mode_map': {'c': 'NORMAL'},
        \ 'active': {
        \   'left': [ [ 'mode', 'paste' ], [ 'fugitive', 'filename' ] ]
        \ },
        \ 'component_function': {
        \   'modified': 'MyModified',
        \   'readonly': 'MyReadonly',
        \   'fugitive': 'MyFugitive',
        \   'filename': 'MyFilename',
        \   'fileformat': 'MyFileformat',
        \   'filetype': 'MyFiletype',
        \   'fileencoding': 'MyFileencoding',
        \   'mode': 'MyMode'
        \ }
        \ }

function! MyModified()
  return &ft =~ 'help\|vimfiler\|gundo' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! MyReadonly()
  return &ft !~? 'help\|vimfiler\|gundo' && &readonly ? 'x' : ''
endfunction

function! MyFilename()
  return ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
        \ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
        \  &ft == 'unite' ? unite#get_status_string() :
        \  &ft == 'vimshell' ? vimshell#get_status_string() :
        \ '' != expand('%:t') ? expand('%:t') : '[No Name]') .
        \ ('' != MyModified() ? ' ' . MyModified() : '')
endfunction

function! MyFugitive()
  try
    if &ft !~? 'vimfiler\|gundo' && exists('*fugitive#head')
      return fugitive#head()
    endif
  catch
  endtry
  return ''
endfunction

function! MyFileformat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
endfunction

function! MyFileencoding()
  return winwidth(0) > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

function! MyMode()
  return winwidth(0) > 60 ? lightline#mode() : ''
endfunction
set cmdheight=2
set showcmd
" show mode
set showmode
set nomodeline
" show title
set title
" highlite parentheses
set showmatch
set matchpairs& matchpairs+=<:>
" last line
set display=lastline
" invisible character
set list
set listchars=tab:»-,trail:-,extends:»,precedes:«,nbsp:%,eol:¬
" cursor
set backspace=indent,eol,start
set whichwrap=b,s,h,l,<,>,[,],~
set scrolloff=8
set sidescrolloff=16
set sidescroll=1
set virtualedit=block
" saving
set confirm
set hidden
set autoread
set nobackup
set noundofile
set noswapfile
autocmd BufWritePre * :%s/\s\+$//e
set viminfo+=n/tmp/.viminfo
" wrap
set wrap
set breakindent
set textwidth=0
set colorcolumn=128
" search
set hlsearch
set incsearch
set ignorecase
set smartcase
set wrapscan
" autoformat
set formatoptions=lmMoq
" show ruler
set ruler
" silence vb
set vb t_vb=
set noerrorbells
" filebrowser
set browsedir=buffer
" wildmenu
set wildmenu
set wildmode=list:full
" mouse
set mouse=a
" clipboard
set clipboard=unnamed,autoselect
"function! ClipboardYank()
"  call writefile( split( @@, "\n" ), '/dev/clipboard' )
"endfunction
"function! ClipboardPaste()
"  let @@ = join( readfile( '/dev/clipboard' ), "\n" )
"endfunction
"vnoremap <silent> y y:call ClipboardYank()<cr>
"vnoremap <silent> d d:call ClipboardYank()<cr>
"nnoremap <silent> p :call ClipboardPaste()<cr>p
" Zenkaku
set ambiwidth=double
function! ZenkakuSpace()
    highlight ZenkakuSpace cterm=reverse ctermfg=DarkMagenta gui=reverse guifg=DarkMagenta
endfunction
if has('syntax')
    augroup ZenkakuSpace
        autocmd!
        autocmd ColorScheme       * call ZenkakuSpace()
        autocmd VimEnter,WinEnter * match ZenkakuSpace /　/
    augroup END
    call ZenkakuSpace()
endif
" extension
au BufNewFile,BufRead *.avs set filetype=avsplus
au BufNewFile,BufRead *.avsi set filetype=avsplus
let g:avs_operator = 1
au BufNewFile,BufRead *.rs set filetype=rust
" mappings
let g:neocomplcache_enable_insert_char_pre = 1
inoremap <C-e> <End>
inoremap <C-a> <Home>
inoremap <C-d> <Del>
inoremap <C-x> <Del>
inoremap <C-h> <BS>
inoremap <Up> <Up>
inoremap <C-_> <ESC>ugi
inoremap <C-\> <ESC>ugi
nnoremap OA gi<Up>
nnoremap OB gi<Down>
nnoremap OC gi<Right>
nnoremap OD gi<Left>
nnoremap OF gi<End>
nnoremap OH gi<Home>
nnoremap [3~ gi<Del>
nnoremap [5~ gi<PageUp>
nnoremap [6~ gi<PageDown>
vnoremap <silent> <C-p> "0p<CR>

" NERDTree
let g:NERDTreeShowBookmarks = 1
let NERDTreeShowHidden = 1
let file_name = expand("%:p")
if has('vim_starting') &&  file_name == ""
    autocmd VimEnter * execute 'NERDTree ./'
endif

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

function! Mytc()
    execute 'tablast'
    execute 'tabnew'
    execute 'NERDTree ./'
endfunction

map <silent> [Tag]c :call Mytc()<CR><C-w>l
" tc 新しいタブを一番右に作る
map <silent> [Tag]x :tabclose<CR>
" tx タブを閉じる
map <silent> [Tag]n :tabnext<CR>
" tn 次のタブ
map <silent> [Tag]p :tabprevious<CR>
" tp 前のタブ
