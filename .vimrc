" vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
	  \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Language stuff
Plug 'othree/html5.vim'
Plug 'othree/html5-syntax.vim'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'posva/vim-vue'
Plug 'stanangeloff/php.vim'
Plug 'vim-perl/vim-perl'

" Other stuff
"
" Sensible defaults
Plug 'tpope/vim-sensible'
" Git integration
Plug 'tpope/vim-fugitive'
" Surrounding stuff w/ stuff
Plug 'tpope/vim-surround'
" File navigator
Plug 'scrooloose/nerdtree'
" Syntax checker
Plug 'scrooloose/syntastic'
" Commenter
Plug 'scrooloose/nerdcommenter'
" Respect local eslintrc with syntastic
Plug 'mtscout6/syntastic-local-eslint.vim'
" JS Tidy
Plug 'maksimr/vim-jsbeautify'
" Handle Extra Whitespace
Plug 'ntpeters/vim-better-whitespace'
" Respect local .editorconfig's
Plug 'editorconfig/editorconfig-vim'
" Tab completion
Plug 'ervandew/supertab'
" Auto-close ({", etc.
Plug 'Raimondi/delimitMate'
" Display ctag list
Plug 'majutsushi/tagbar'
" Seamless vim and tmux nav
Plug 'christoomey/vim-tmux-navigator'
" Fuzzy finder
Plug 'ctrlpvim/ctrlp.vim'
" Edit .tmux.conf sanely
Plug 'tmux-plugins/vim-tmux'
" Vim status line and themes
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Tmux status line
Plug 'edkolev/tmuxline.vim'
" Dracula theme, also provides airline theme
Plug 'dracula/vim'

call plug#end()

"""""""""""
" General "
"""""""""""

" Set mapleader
let mapleader=","

" Set backup, undo and swap directories.
call system('mkdir ~/.vim/backup')
call system('mkdir ~/.vim/swp')
set backupdir=~/.vim/.backup//
set directory=~/.vim/.swp//

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file
endif

set nocompatible
set showcmd			" display incomplete commands
set number
set relativenumber
set numberwidth=2
set showmatch
set wrap 			" Wrap lines
set cindent
set showmatch
set showfulltag

" Press <Space> to toggle search highlighting in command mode
map <silent> <Space> :silent set hlsearch!<bar>:echo ""<CR>

" quicker buffer navigation
nnoremap <C-n> :next<CR>
nnoremap <C-p> :prev<CR>

" get the commandline more quickly
nnoremap ; :

" movement makes sense across wrapped lines
nnoremap j gj
nnoremap k gk
imap <up> <c-o>gk
imap <down> <c-o>gj

" make F1 just another esc key
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

" nuke shifted up/down arrow keys in insert mode
inoremap <S-Up> <nop>
inoremap <S-Down> <nop>

" For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries
" let &guioptions = substitute(&guioptions, "t", "", "g")

" Don't use Ex mode, use Q for formatting
map Q gq

" In many terminal emulators the mouse works just fine, thus enable it.
set mouse=a

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

"""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""
" Language Settings  "
""""""""""""""""""""""

" General
set tabstop=4 shiftwidth=4 softtabstop=0 textwidth=78 noexpandtab nosta autoindent

" HTML
" au BufEnter *.html set

" CSS
au BufEnter *.css set ts=2 sw=2 sts=2 expandtab sta

" JS
" au BufEnter *.js,*.jsx set

" Perl
" au BufEnter *.pm,*.pl,*.tp set

" Python
au BufEnter *.py set tw=78 sta et fo=croql

" Ruby
au BufEnter *.ruby,*.rb set sw=2 ts=2 sts=2
autocmd FileType ruby,rdoc,cucumber,yaml set sts=2 tabstop=2 sw=2
autocmd BufNewFile,BufRead Gemfile setfiletype ruby
autocmd BufNewFile,BufRead Berksfile setfiletype ruby
autocmd BufNewFile,BufRead Vagrantfile setfiletype ruby

"""""""""""""""""""""""""""""""""""""""

"""""""""""""""
" Colorscheme "
"""""""""""""""

" Set colorscheme
set t_Co=256
colorscheme dracula

"""""""""""""""""""""""""""""""""""""""

"""""""""""""""""""""""""
" Vim-better-whitespace "
"""""""""""""""""""""""""

" Change highlight color
highlight ExtraWhitespace ctermbg=white

"""""""""""""""""""""""""""""""""""""""

"""""""""""""""
" Vim-airline "
"""""""""""""""

" Set vim-airline theme (Left off, dracula provides theme)
" let g:airline_theme= 'wombat'

"""""""""""""""""""""""""""""""""""""""

""""""""""""""""
" Vim-tmuxline "
""""""""""""""""

" Set tmuxline preset
let g:tmuxline_preset = 'powerline'

"""""""""""""""""""""""""""""""""""""""

""""""""""""""
" JsBeautify "
""""""""""""""

map <c-f> :call JsBeautify()<cr>
autocmd FileType javascript vnoremap <buffer>  <c-f> :call RangeJsBeautify()<cr>
autocmd FileType json vnoremap <buffer> <c-f> :call RangeJsonBeautify()<cr>
autocmd FileType jsx vnoremap <buffer> <c-f> :call RangeJsxBeautify()<cr>
autocmd FileType html vnoremap <buffer> <c-f> :call RangeHtmlBeautify()<cr>
autocmd FileType css vnoremap <buffer> <c-f> :call RangeCSSBeautify()<cr>

"""""""""""""""""""""""""""""""""""""""

"""""""""""""
" Syntastic "
"""""""""""""

let g:syntastic_mode_map = {
	\ "mode": "passive",
    \ "active_filetypes": ['html', 'php', 'js', 'javascript'],
    \ "passive_filetypes": [], }

" Perl
let g:syntastic_perl_checkers = ['perl']
let g:syntastic_enable_perl_checker = 1

" JS
let g:syntastic_javascript_checkers = ['eslint']

" Set F2 to SyntasticCheck
map <F2> :SyntasticCheck<CR>

"""""""""""""""""""""""""""""""""""""""

"""""""""""""
" vim-jsx   "
"""""""""""""

" JSX
let g:jsx_ext_required = 0 " Allow JSX in normal JS files

"""""""""""""""""""""""""""""""""""""""

""""""""""""
" Taglist  "
""""""""""""

" Set F3 to toggle taglist
nnoremap <silent> <F3> :TagbarToggle <CR>

"""""""""""""""""""""""""""""""""""""""

"""""""""""""
" NERDTree  "
"""""""""""""

" Set F4 to toggle NERDTree, auto open, auto close and focus on prev window
" autocmd vimenter * NERDTree
" autocmd VimEnter * wincmd p
let NERDTreeShowHidden=1
map <F4> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

"""""""""""""""""""""""""""""""""""""""

""""""""""""""""""
" NERDCommenter  "
""""""""""""""""""

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

"""""""""""""""""""""""""""""""""""""""

"""""""""""
" Fennec  "
"""""""""""

function! RunFennecLine()
    let cur_line = line(".")
    exe "!FENNEC_TEST='" . cur_line . "' prove -v -Ilib -I. -I/home/rmiller/ndn/perl %"
endfunction

function! RunFennecWholeFile()
    let cur_line = line(".")
    exe "!prove -v -Ilib -I. -I/home/rmiller/ndn/perl %"
endfunction

function! RunFennecLineLess()
    let cur_line = line(".")
    exe "!FENNEC_TEST='" . cur_line . "' prove -v -Ilib -I. -I/home/rmiller/ndn/perl % 2>&1 | less"
endfunction

:map <F8> :w<cr>:call RunFennecLine()<cr>
:map <F9> :w<cr>:call RunFennecWholeFile()<cr>
:map <F10> :w<cr>:call RunFennecLineLess()<cr>

:imap <F8> <ESC>:w<cr>:call RunFennecLine()<cr>
:imap <F9> <ESC>:w<cr>:call RunFennecWholeFile()<cr>
:imap <F10> <ESC>:w<cr>:call RunFennecLineLess()<cr>

"""""""""""""""""""""""""""""""""""""""

"""""""""""""
" Perltidy  "
"""""""""""""

" Run perltidy on selection with ,dt
if filereadable('/ndn/etc/perltidyrc') && filereadable('/ndn/perl/bin/partialtidy.pl')
	:map <Leader>dt :!/ndn/perl/bin/partialtidy.pl /ndn/etc/perltidyrc<CR>
else
	nnoremap <silent> <Leader>dt :%!perltidy -q<Enter>
	vnoremap <silent> <Leader>dt :!perltidy -q<Enter>
endif

"""""""""""""""""""""""""""""""""""""""
