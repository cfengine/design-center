# Time-stamp: <2012-10-01 00:50:24 a10022>
#
# search command for searching through sketch list
# Diego Zamboni, October 1st, 2012.
# diego.zamboni@cfengine.com

%COMMANDS =
  (
   'search' =>
   [[
     'search all|regex',
     'Search sketch repository, use "all" to list everything.',
     '(.*)'
    ]]
  );

######################################################################

sub command_search {
  my $regex=shift;
  my $err = Util::check_regex($regex);
  if ($err) {
    Util::error($err);
  }
  else {
    CFSketch::search($regex eq 'all' ? ["."] : [$regex]);
  }
}

1;
