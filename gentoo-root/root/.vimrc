call system('mkdir -p ~/.vimswaps/ ~/.vimundo/ ; chmod 700 ~/.vimswaps ~/.vimundo')

set directory=~/.vimswaps//
set ignorecase
set smartcase
"set foldmethod=indent
set foldmethod=manual
set foldlevel=4
"set textwidth=80
set textwidth=0
set nocompatible
set ruler
set showcmd
set nu
set incsearch
set nohlsearch
set scrolljump=4
set scrolloff=4
set novisualbell
set t_vb=
"set mouse=a
set mouse=n
set mousemodel=popup
set mousehide
set termencoding=utf-8
set guioptions-=T
set ch=1
set sessionoptions=curdir,buffers,tabpages
set bs=2                " Allow backspacing over everything in insert mode
set ai                  " Always set auto-indenting on
set history=50          " keep 50 lines of command history
set ruler               " Show the cursor position all the time
set tags=tags,.tags,rusty-tags.vi
set tags+=tags;/
se number
" se relativenumber
set shortmess=aAoOtIT
set nowritebackup
set undodir=~/.vimundo
set undofile

" put cursor to real end of line in normal mode
set ve+=onemore
nnoremap $ $l
au InsertLeave * call cursor([getpos('.')[1], getpos('.')[2]+1])

set fileencodings=utf-8,cp1251,koi8-r,cp866
set wildmenu
set wcm=<Tab>
menu Encoding.koi8-r :e ++enc=koi8-r<Enter>
menu Encoding.windows-1251 :e ++enc=cp1251<Enter>
menu Encoding.cp866 :e ++enc=cp866<Enter>
menu Encoding.utf-8 :e ++enc=utf8 <Enter>
menu Encoding.utf-16 :e ++enc=utf16 <Enter>
map <F8> :emenu Encoding.<TAB>

set spelllang=en,ru
"map <S-s> :set spell!<Enter>
map <F7> :set spell!<Enter>
imap <F7> <esc>:set spell!<Enter>
map <A-n> :set nu!<Enter>

" allow to use backspace instead of "x"
set backspace=indent,eol,start whichwrap+=<,>,[,]

" tab to spaces
set expandtab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set laststatus=2

" Fix <Enter> for comment
set fo+=cr


" got to last edited location
map <C-k> ''
map <C-j> ''
imap <C-k> <esc>''
imap <C-j> <esc>''
vmap <C-k> ''
vmap <C-j> ''


" Indents
set smartindent  " indent after {, etc.
set autoindent
vmap < <gv
vmap > >gv
vmap <tab> >gv
vmap <S-tab> <gv

" auto closing character
" imap [ []<LEFT>
imap {<Enter> {<Enter>}<Esc>O

" Autoclose quickfix list after leaving it
autocmd WinEnter * cclose


" Terminal hacks

" C-h for xterm + tmux + nvim
"if &term == "screen"
noremap <bs> :tabp<Enter>
"endif

"set term=xterm
if v:version >= 700
  set numberwidth=3
endif

if &term ==? "xterm"
  set t_Sb=^[4%dm
  set t_Sf=^[3%dm
  set ttymouse=xterm2
endif

" requires https://www.vinc17.net/unix/ctrl-backspace.en.html
inoremap <C-Home> <C-w>

map . /
map U <esc>:redo<Enter>

" Clipboard
vmap <C-C> "+yi
"imap <C-V> <esc>"+gPi
imap <C-S-v> <esc>"*pi
set clipboard=unnamedplus

map <C-t> :tabnew<Enter>
imap <C-t> <esc>:tabnew<Enter>
vmap <C-t> <esc>:tabnew<Enter>

" file browser
map <C-F3> :tabnew<Enter>:Ex<Enter>
imap <C-F3> <esc>:tabnew<Enter>:Ex<Enter>
vmap <C-F3> <esc>:tabnew<Enter>:Ex<Enter>
command! E Explore

noremap <C-l> :tabn<Enter>
noremap <C-h> :tabp<Enter>

noremap <S-H> :-tabmove<Enter>
noremap <S-L> :+tabmove<Enter>

vmap <C-l> <esc>:tabn<Enter>
vmap <C-h> <esc>:tabp<Enter>
vmap <bs> <esc>:tabp<Enter>


" shift-insert behavior is similar to xterm
"map <S-Insert> <MiddleMouse>

" enter insert mode after the cursor
map <S-i> a

"" swap a and i
" nnoremap i a
" nnoremap a i

" search and replace current word
nmap ; :%s/\<<c-r>=expand("<cword>")<Enter>\>/





map cc <esc>:q<Enter>

imap <C-Del> X<Esc>ce
map <C-Del> dw

" sort lines and remove empty ones
vmap s :sort<Enter>:'<,'>g/^\s*$/d<Enter>

" Tagbar
let g:tagbar_autoclose = 1
let g:tagbar_autofocus = 1
map <F12> :TagbarToggle<Enter>
imap <F12> <esc>:TagbarToggle<Enter>
vmap <F12> <esc>:TagbarToggle<Enter>


"urxvt and others terminals hack
map <End> $


function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction

augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END


" File types / Languages
filetype on
filetype plugin indent on

au BufNewFile,BufRead *.toml set filetype=toml
au BufNewFile,BufRead Cargo.lock set filetype=toml
au BufNewFile,BufRead *.frag,*.vert,*.fp,*.vp,*.glsl setf glsl
autocmd BufNewFile,BufRead *.ny set syntax=lisp
autocmd BufNewFile,BufRead *.xges set syntax=xml
autocmd BufNewFile,BufRead *.ncl set syntax=haskell
autocmd BufNewFile,BufRead *.ym{a,}l_debug set syntax=yaml

" txt
" Disable annoying auto line break
fu! DisableBr()
  set wrap
  set linebreak
  set nolist  " list disables linebreak
  set textwidth=0
  set wrapmargin=0
  set fo-=t
endfu
au BufNewFile,BufRead *.txt call DisableBr()

au FileType markdown vmap a :EasyAlign*<Bar><Enter>

autocmd BufEnter,FocusGained * checktime


" Colors
hi default link BqfPreviewTitle TabLineSel
hi SpellBad cterm=underline
hi ModeMsg term=bold cterm=bold gui=bold
hi DiffText term=reverse cterm=bold gui=bold guibg=Red
hi Directory term=bold
hi MoreMsg term=bold gui=bold
hi NonText term=bold gui=bold
hi Question term=standout gui=bold
hi SpecialKey term=bold
hi Title term=bold gui=bold
hi DiffAdd term=bold
hi DiffChange term=bold
hi DiffDelete term=bold gui=bold
hi Special term=bold ctermfg=red
hi Statement term=bold cterm=bold gui=bold
hi Type ctermfg=4 cterm=bold
hi String ctermfg=5 cterm=bold
hi Comment ctermfg=6 cterm=bold
hi LineNr ctermfg=3 cterm=bold
hi Search ctermfg=0
hi Constant cterm=bold
hi StatusLineNC cterm=bold ctermfg=0
hi Title ctermfg=LightBlue ctermbg=Magenta
hi PreProc cterm=bold ctermfg=4
hi CursorLineNr ctermfg=Yellow
set cursorline
hi Folded ctermfg=darkgreen ctermbg=black
hi Visual ctermbg=darkblue term=bold
hi StatusLine ctermfg=white ctermbg=darkblue cterm=none
hi PmenuSel ctermfg=black ctermbg=yellow cterm=none guibg=red gui=bold
highlight Pmenu ctermfg=NONE ctermbg=NONE
hi TabLineSel term=bold  ctermfg=black ctermbg=green
hi TabLine ctermfg=white ctermbg=black
hi TabLineFill term=bold,reverse  cterm=bold ctermfg=lightblue ctermbg=black
hi TabLineSel ctermfg=black ctermbg=darkgreen cterm=NONE
hi Todo ctermfg=gray ctermbg=darkblue

highlight clear SpellBad
highlight clear SpellCap
highlight clear SpellLocal
highlight clear SpellRare

highlight SpellBad cterm=underline
highlight SpellCap cterm=underline
highlight SpellLocal cterm=underline
highlight SpellRare cterm=underline

if $DISPLAY != ''
	colorscheme default
else
	colorscheme evening
endif

hi Normal ctermfg=lightgrey
hi Normal ctermbg=black
hi Type ctermfg=blue
hi Special term=bold cterm=bold
hi Folded ctermfg=white ctermbg=black
hi Visual ctermbg=darkcyan
hi StatusLine ctermfg=black ctermbg=darkred cterm=none
hi TabLineSel term=bold  ctermfg=white ctermbg=darkblue
hi TabLine ctermfg=white ctermbg=black
hi TabLineFill term=bold,reverse  cterm=bold ctermfg=lightblue ctermbg=black

" vim:shiftwidth=2 softtabstop=2 tabstop=2
