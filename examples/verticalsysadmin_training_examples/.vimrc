" Your vim settings need include "exrc" to pick up this .vimrc file
" automatically. In other words, add "set exrc" to your $HOME/.vimrc
" Mind the security implications of doing so.


" CFEngine syntax highlighing
filetype plugin on
syntax on
autocmd BufRead,BufNewFile *.cf set ft=cf3

" Disable folding so it does not confuse students not familiar with it
set nofoldenable 

" asciidoc syntax highlighting
autocmd BufRead,BufNewFile *.asciidoc set ft=asciidoc

" run current file using cf-agent
map ff :!clear;/var/cfengine/bin/cf-agent -KIb example -f '%:p'

" run current file using cf-agent in verbose mode
map vv :!clear;/var/cfengine/bin/cf-agent -KIvb example -f '%:p' \| less

" run current file using /bin/sh
map rr :!clear;/bin/sh '%:p'

" use SPACE and BACKSPACE to control the run_slides.sh slideshow
map <SPACE> :next<CR>
map <BACKSPACE> :prev<CR>:<CR>gg

" Make your status line always visible to show the name of the file
set laststatus=2
" Add file name to your statusline
set statusline+=%f

" Remap Tab to Esc
" nnoremap <Tab> <Esc>
" vnoremap <Tab> <Esc>gV
" onoremap <Tab> <Esc>
" inoremap <Tab> <Esc>`^
" inoremap <Leader><Tab> <Tab>

" Map jk to Esc - it's fast!
"imap jk <Esc>


" Neil Watson recommends installing functions Eatchar and Getchar
fun! Getchar()
  let c = getchar()
  if c != 0
    let c = nr2char(c)
  endif
  return c
endfun

fun! Eatchar(pat)
  let c = Getchar()
  return (c =~ a:pat) ? '' : c
endfun

" disable abbreviations so we do not confuse students
let g:DisableCFE3KeywordAbbreviations=0
