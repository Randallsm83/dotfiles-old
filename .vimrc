set nocompatible

filetype off

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim

" call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
let path='~/vimplugins/'
call vundle#begin(path)

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.

" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-surround'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'ervandew/supertab'
Plugin 'Raimondi/delimitMate'
Plugin 'majutsushi/tagbar'
Plugin 'vim-perl/vim-perl'
Plugin 'tmux-plugins/vim-tmux'
Plugin 'bling/vim-airline'

" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'

" Git plugin not hosted on GitHub
" Plugin 'git://git.wincent.com/command-t.git'

" git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'

" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}

" Avoid a name conflict with L9
" Plugin 'user/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
" Vundle End

" Always show status bar
set laststatus=2

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" Set backup, undo and swap directories.
set backupdir=~/.vim/.backup//
set directory=~/.vim/.swp//

" Highlight whitespace
highligh ExtraWhitespace ctermbg=white guibg=white
:match ExtraWhitespace /\s\+$/
:autocmd ColorScheme * highlight ExtraWhitespace ctermbg=white guibg=white

" Set colorscheme
set t_Co=256
colorscheme molokai
let g:molokai_original = 1
let g:rehash256 = 1

" Set vim-airline theme
let g:airline_theme='wombat'

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file
endif

syntax enable
syntax on

set history=500		" keep 500 lines of command line history
set ruler			" show the cursor position all the time
set showcmd			" display incomplete commands
set incsearch		" do incremental searching'
set number
set showmatch
set wrap 			" Wrap lines
set cindent
set showmatch
set showfulltag
set tabstop=4 shiftwidth=4 softtabstop=0 noexpandtab autoindent

au BufEnter *.py set ai sw=4 ts=4 tw=76 sta et fo=croql
au BufEnter *.pm,*.pl,*.tp set tw=0

" Ruby
au BufEnter *.ruby set sw=2 ts=2 sts=2
autocmd BufNewFile,BufRead Gemfile set filetype=ruby
autocmd BufNewFile,BufRead Vagrantfile set filetype=ruby
autocmd BufNewFile,BufRead Berksfile set filetype=ruby

" Enable syntastic for perl
let g:syntastic_perl_checkers = ['perl']
let g:syntastic_enable_perl_checker = 1
let g:syntastic_mode_map = { "mode": "passive",
                               \ "active_filetypes": [],
                               \ "passive_filetypes": [] }
" Set F2 to SyntasticCheck
map <F2> :SyntasticCheck<CR>

" Set F3 to toggle taglist
nnoremap <silent> <F3> :TagbarToggle <CR>

" Set F4 to toggle NERDTree, auto open, auto close and focus on prev window
" autocmd vimenter * NERDTree
" autocmd VimEnter * wincmd p
let NERDTreeShowHidden=1
map <F4> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

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

" Start Vim-Helper plugin: Fennec
function! RunFennecLine()
    let cur_line = line(".")
    exe "!FENNEC_TEST='" . cur_line . "' prove -v -Ilib -I. -I/home/rmiller/ndn/perl %"
endfunction

function! RunFennecLineLess()
    let cur_line = line(".")
    exe "!FENNEC_TEST='" . cur_line . "' prove -v -Ilib -I. -I/home/rmiller/ndn/perl % 2>&1 | less"
endfunction

:map <F12> :w<cr>:call RunFennecLineLess()<cr>
:map <F8> :w<cr>:call RunFennecLine()<cr>

:imap <F12> <ESC>:w<cr>:call RunFennecLineLess()<cr>
:imap <F8> <ESC>:w<cr>:call RunFennecLine()<cr>
" End Vim-Helper plugin: Fennec

" Run perltidy on selection with \dt
if filereadable('/ndn/etc/perltidyrc') && filereadable('/ndn/perl/bin/partialtidy.pl')
	:map <Leader>dt :!/ndn/perl/bin/partialtidy.pl /ndn/etc/perltidyrc<CR>
else
	nnoremap <silent> <Leader>dt :%!perltidy -q<Enter>
	vnoremap <silent> <Leader>dt :!perltidy -q<Enter>
endif

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

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  augroup END

else

  set autoindent		" always set autoindenting on

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
"	 	\ | wincmd p | diffthis

