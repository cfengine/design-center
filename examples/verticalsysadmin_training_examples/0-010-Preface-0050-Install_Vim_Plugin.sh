#!/bin/sh
# Run this shell script to install Neil Watson's CFEngine 3 syntax highlighter
cat <<EOF >> ~/.vimrc

filetype plugin on
syntax enable
au BufRead,BufNewFile *.cf set ft=cf3
" Disable folding so it does not confuse students not familiar with it
if exists("&foldenable")
	set nofoldenable 
endif

" disable abbreviations so we do not confuse students
let g:DisableCFE3KeywordAbbreviations=0

" functions Eatchar and Getchar
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

EOF

echo Install syntax highlighter and editor plugin

mkdir -p ~/.vim/ftplugin  ~/.vim/syntax 

wget -O ~/.vim/syntax/cf3.vim \
      https://github.com/neilhwatson/vim_cf3/raw/master/syntax/cf3.vim

wget -O ~/.vim/ftplugin/cf3.vim \
      https://github.com/neilhwatson/vim_cf3/raw/master/ftplugin/cf3.vim
