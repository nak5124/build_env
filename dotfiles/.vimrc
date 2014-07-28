" vim:set ts=4 sts=4 sw=4 expandtab:
set nocompatible
set modeline
" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencoding=utf-8
set fileencodings=iso-2022-jp,utf-8,cp932,euc-jp,ucs-2,sjis,default,latin
set fileformat=unix
" scheme
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
"set clipboard=unnamed,autoselect
function! ClipboardYank()
  call writefile( split( @@, "\n" ), '/dev/clipboard' )
endfunction
function! ClipboardPaste()
  let @@ = join( readfile( '/dev/clipboard' ), "\n" )
endfunction
vnoremap <silent> y y:call ClipboardYank()<cr>
vnoremap <silent> d d:call ClipboardYank()<cr>
nnoremap <silent> p :call ClipboardPaste()<cr>p
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
inoremap <C-p> <Up>
inoremap <C-n> <Down>
inoremap <C-b> <Left>
inoremap <C-f> <Right>
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
" https://github.com/fuenor/vim-statusline/blob/master/insert-statusline.vim
if !exists('g:hi_insert')
    let g:hi_insert = 'highlight StatusLine guifg=White guibg=DarkCyan gui=none ctermfg=White ctermbg=DarkCyan cterm=none'
endif

if has('unix') && !has('gui_running')
    inoremap <silent> <ESC> <ESC>
    inoremap <silent> <C-[> <ESC>
endif

if has('syntax')
    augroup InsertHook
        autocmd!
        autocmd InsertEnter * call s:StatusLine('Enter')
        autocmd InsertLeave * call s:StatusLine('Leave')
    augroup END
endif

let s:slhlcmd = ''
function! s:StatusLine(mode)
    if a:mode == 'Enter'
        silent! let s:slhlcmd = 'highlight ' . s:GetHighlight('StatusLine')
        silent exec g:hi_insert
    else
        highlight clear StatusLine
        silent exec s:slhlcmd
    endif
endfunction

function! s:GetHighlight(hi)
    redir => hl
    exec 'highlight '.a:hi
    redir END
    let hl = substitute(hl, '[\r\n]', '', 'g')
    let hl = substitute(hl, 'xxx', '', '')
    return hl
endfunction
