# Time-stamp: <2012-10-09 10:02:16 a10022>
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
  $regex = "." if ($regex eq 'all' or !$regex);
  my $err = Util::check_regex($regex);
  if ($err) {
    Util::error($err);
  } else {
    @res = DesignCenter::Config->_repository->search($regex);
    if (@res) {
      Util::output("The following sketches ".(($regex eq '.')?"are available:":"match your query:")."\n\n");
      foreach my $found (@res) {
        print GREEN, $found->name, RESET, " ".$found->location."\n";
      }
    }
    else {
      Util::error("No sketches match your query.\n");
    }
  }
}

1;
