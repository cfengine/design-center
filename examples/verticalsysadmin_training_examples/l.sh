#!/bin/sh
# colorize "ls" output
ls -1F| \
  perl -e '$oldchapter=0; while (<STDIN>) { /^(\d\d\d)/; $chapter = $1;  if ($chapter != $oldchapter) { print "$chapter\n"; $oldchapter = $chapter; };  print; }; $purpose_of_this_script = "insert chapter breaks based on the first three digits in each line.   input: 010-... 010-..... 020-.... 020-.... etc.  insert the chapter break between 010 and 020.";' | \
  remark ./VSAcf3.remark | \
  less -r  # the -r switch preserves the colorization codes

# note: remark is provided by regex-markup from nongnu.org
