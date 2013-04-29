#!/bin/sh
# colorize "ls" output


# l.sh depends on "remark" which is provided by "regex-markup" from nongnu.org.
# let's check that "remark" is installed, and if it's not, then install it
remark /dev/null /dev/null >/dev/null 2>/dev/null || (echo; echo; echo Installing regex-markup RPM; sh -x -c 'wget http://download.savannah.gnu.org/releases/regex-markup/regex-markup-0.10.0-1.x86_64.rpm' && rpm -ihv ./regex-markup-0.10.0-1.x86_64.rpm; echo press ENTER to continue; read A)


# display a colorized file list, in alphanumeric order

ls -1F| \
  perl -e '$oldchapter=0; while (<STDIN>) { /^(\d\d\d)/; $chapter = $1;  if ($chapter != $oldchapter) { print "$chapter\n"; $oldchapter = $chapter; };  print; }; $purpose_of_this_script = "insert chapter breaks based on the first three digits in each line.   input: 010-... 010-..... 020-.... 020-.... etc.  insert the chapter break between 010 and 020.";' | \
  remark ./VSAcf3.remark | \
  less -r  # the -r switch preserves the colorization codes

