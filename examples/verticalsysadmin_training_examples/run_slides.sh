#!/bin/sh

# Purpose: show cfengine examples using vim.  This allows us
# to edit the examples during the presentation.
#
# Note: there is a .vimrc in this directory. You have to
# have "set exrc" enabled for vim to load it automatically.


# slideshow requires the following to render asciidoc slides:
for REQUIRED in asciidoc elinks 
do
  # check if it is installed, and if not, install it
  [ -x `which ${REQUIRED}` ] || \
  (
     # try to guess the package mgr
     sudo yum install ${REQUIRED} 2>/dev/null  || sudo apt-get install ${REQUIRED} 2>/dev/null
  )
done

# pygments is used to colorize/syntax-highlight code
[ -x `which pygmentize` ] || sudo yum install python-pygments || sudo apt-get install python-pygments

# libreoffice-impress is used to display a presentation
[ -x `which libreoffice` ] || sudo yum install libreoffice-impress || sudo apt-get install libreoffice-impress

# start slideshow
vim `ls -1 | egrep -v '.png$|.pdf$' `
