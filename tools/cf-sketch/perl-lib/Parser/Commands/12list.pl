#
# list command for displaying installed sketches
#
# CFEngine AS, October 2012
# Time-stamp: <2012-10-08 21:57:36 a10022>

use Term::ANSIColor qw(:constants);

use Util;
use DesignCenter::Config;

######################################################################

%COMMANDS =
  (
   'list' =>
   [[
     'list [REGEX|all]',
     'List installed sketches. Specify REGEX to filter, no argument or "all" to list everything.',
     '(.*)'
    ]]
  );

######################################################################

sub command_list {
  my $regex=shift;
  my $err = Util::check_regex($regex);
  if ($err) {
    Util::error($err);
  } else {
    DesignCenter::Config->_system->list([$regex eq 'all' ? "." : $regex]);
    # @res = $Config{_repository}->list($regex eq 'all' ? "." : $regex);
    # foreach my $found (@res) {
    #   print GREEN, $found->name, RESET, " ".$found->location."\n";
    # }
  }
}
