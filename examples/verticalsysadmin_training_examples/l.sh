#!/bin/sh

# colorize "ls" output to read the table of contents for the course materials.  
# differentiate chapter numberting from section numbering from section titles;
# highlight in red file names that do not match expected pattern.
# Aleksey Tsalolikhin

install_remark() {
  echo
  echo
  echo Installing regex-markup

  if [ -f /bin/rpm ]
  then
          sh -x -c 'wget http://download.savannah.gnu.org/releases/regex-markup/regex-markup-0.10.0-1.x86_64.rpm' && sudo rpm -ihv ./regex-markup-0.10.0-1.x86_64.rpm
  fi

  if [ -f /usr/bin/dpkg ]
  then
	  echo got this far
	  sh -x -c 'wget  http://gnu.mirrors.pair.com/savannah/savannah/regex-markup/regex-markup_0.10.0-1_amd64.deb' && sudo dpkg -i ./regex-markup_0.10.0-1_amd64.deb
  fi

  echo press ENTER to continue; read A
}


# l.sh depends on "remark" which is provided by "regex-markup" from nongnu.org.
# let's check that "remark" is installed, and if it's not, then install it
remark /dev/null /dev/null >/dev/null 2>/dev/null || install_remark


# display a colorized file list, in alphanumeric order

ls -1F| \
  perl -e '$oldchapter=0; while (<STDIN>) { /^(\d\d\d)/; $chapter = $1;  if ($chapter != $oldchapter) { print "$chapter\n"; $oldchapter = $chapter; };  print; }; $purpose_of_this_script = "insert chapter breaks based on the first three digits in each line.   input: 010-... 010-..... 020-.... 020-.... etc.  insert the chapter break between 010 and 020.";' | \
  remark ./VSAcf3.remark | \
  less -r  # the -r switch preserves the colorization codes

