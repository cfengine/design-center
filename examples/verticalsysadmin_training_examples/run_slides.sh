#!/bin/sh

# Purpose: show all my cfengine examples using vim.  this allows me to edit them during the presentation.

# note: there is a .vimrc in this directory.
# you have to have "set exrc" enabled for vim to load it automatically

for f in `ls -1`
do
  vim $f
done
