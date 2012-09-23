# colorize "ls" output
ls -1| perl -e '$oldchapter=0; while (<STDIN>) { $chapter = substr($_,0,3);  if ($chapter != $oldchapter) { print "$chapter\n"; $oldchapter = $chapter; };  print; }' | \
remark ./VSAcf3.remark | less -r
