#!/bin/sh
# Run this shell script to add the following to your .vimrc:
# - Neil Watson's CFEngine 3 syntax highlighter (minus folding and keyword
#   abbreviations)
# - AsciiDoc syntax highlighter (the slides are written in AsciiDoc) 
# - CFEngine 3 Training Examples "vim slideshow" keybindings


cat <<EOF >> $HOME/.vimrc

" -------- start of  .vimrc settings from Vertical Sysadmin training examples collection
"
" Neil Watson recommends installing functions Getchar and Eatchar for his CF3
" Syntax Highlighter
"
" function Getchar
fun! Getchar()
  let c = getchar()
  if c != 0
    let c = nr2char(c)
  endif
  return c
endfun

" function Eatchar
fun! Eatchar(pat)
  let c = Getchar()
  return (c =~ a:pat) ? '' : c
endfun

" Syntax highlighting for CFEngine 3
filetype plugin on
syntax enable
au BufRead,BufNewFile *.cf set ft=cf3

" Disable folding so it does not confuse students not familiar with it
if exists("&foldenable")
	set nofoldenable 
endif

" disable abbreviations so it does not confuse students not familiar with it
let g:DisableCFE3KeywordAbbreviations=0

" Syntax highlighting for AsciiDoc
autocmd BufRead,BufNewFile *.txt set ft=asciidoc

" The following are mappings to support the Training Examples vim "slideshow"

" use F7 and BACKSPACE to control the run_slides.sh slideshow (move
" forwards and backwards)
map <F7> :next +1<CR>
map <BACKSPACE> :prev +1<CR>

" run current "f"ile using cf-agent in Inform mode
map ff :!clear;/var/cfengine/bin/cf-agent --color=always -KIb example -f '%:p'

" run current file using cf-agent in Verbose mode
map vv :!clear;/var/cfengine/bin/cf-agent --color=always -KIvb example -f '%:p' \| less -R

" run current file using /bin/sh
map rr :!clear;/bin/sh '%:p'


" run asciidoc to render AsciiDoc file; display it with elinks
" but filter out the Last-updated footer that elinks adds.
" Throw away warnings from asciidoc; some heading levels generate 
" warnings when processed standalone but they are needed for the
" compiled materials (in book form) to be more readable.
map tt :!clear;asciidoc -a source-highlighter=pygments -o - '%:p' 2>/dev/null \| elinks -dump -config-dir $HOME -config-file vsa-elinks.conf \| grep -v '^   Last updated '

" autocommand to render asciidoc files (*.txt) (should be the same as "tt" mapping above)
:autocmd BufRead *.txt :!clear; asciidoc -a source-highlighter=pygments -o - '%:p' 2>/dev/null  | elinks -dump -config-dir $HOME -config-file vsa-elinks.conf | grep -v '^   Last updated '

" Make status line visible
set laststatus=2

" Add file name to statusline so we know where we are in the slideshow
set statusline+=%f

" -------- end of  .vimrc settings from Vertical Sysadmin training examples collection
EOF

echo Download and install syntax highlighter vim editor plugin

mkdir -p ~/.vim/ftplugin  ~/.vim/syntax 

wget -O ~/.vim/syntax/cf3.vim \
      https://github.com/neilhwatson/vim_cf3/raw/master/syntax/cf3.vim

wget -O ~/.vim/ftplugin/cf3.vim \
      https://github.com/neilhwatson/vim_cf3/raw/master/ftplugin/cf3.vim
