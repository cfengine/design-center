#!/bin/sh

# Purpose: show cfengine examples using vim.  This allows us
# to edit the examples during the presentation.
#
# Note: there is a .vimrc in this directory. You have to
# have "set exrc" enabled for vim to load it automatically.

for f in `ls -1`
do
  vim $f
done
