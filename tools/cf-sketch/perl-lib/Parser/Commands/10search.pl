# Time-stamp: <2012-10-09 00:14:02 a10022>
#
# search command for searching through sketch list
# Diego Zamboni, October 1st, 2012.
# diego.zamboni@cfengine.com

use Term::ANSIColor qw(:constants);

use DesignCenter::Config;

%COMMANDS =
  (
   'search' =>
   [[
     'search [REGEX | all]',
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
  } else {
    @res = DesignCenter::Config->_repository->search($regex eq 'all' ? "." : $regex);
    foreach my $found (@res) {
      print GREEN, $found->name, RESET, " ".$found->location."\n";
    }

  }
}

1;
