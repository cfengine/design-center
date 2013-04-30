" Your vim settings need include "exrc" to pick up this .vimrc file
" automatically. In other words, add "set exrc" to your $HOME/.vimrc
" Mind the security implications of doing so.


" CFEngine syntax highlighing
filetype plugin indent on
autocmd BufRead,BufNewFile *.cf set ft=cf3
autocmd BufRead,BufNewFile *.asciidoc set ft=asciidoc

" run current file using cf-agent
map ff :!clear;/var/cfengine/bin/cf-agent -KIb example -f '%:p'
map vv :!clear;/var/cfengine/bin/cf-agent -KIvb example -f '%:p' \| less

" run current file using /bin/sh
map rr :!clear;/bin/sh '%:p'

" use SPACE and BACKSPACE to control the slideshow
map <SPACE> :next<CR>
map <BACKSPACE> :prev<CR>:<CR>gg

" Make your status line always visible
set laststatus=2

" Add file name to your statusline
set statusline+=%f
