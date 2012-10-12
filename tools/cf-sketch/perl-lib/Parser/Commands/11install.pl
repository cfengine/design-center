# Time-stamp: <2012-10-08 11:25:54 a10022>
#
# search command for searching through sketch list
# Diego Zamboni, October 1st, 2012.
# diego.zamboni@cfengine.com

use Term::ANSIColor qw(:constants);

use DesignCenter::Config;

######################################################################

%COMMANDS =
  (
   'install' =>
   [[
     'install SKETCH ...',
     'Install or update the given sketches',
     '(.+)'
    ]]
  );

######################################################################

sub command_install {
  my $sketchstr = shift;
  my $sketches = [ split /[,\s]+/, $sketchstr ];
  DesignCenter::Config->_repository->install($sketches)
}

# sub command_search {
#   my $regex=shift;
#   my $err = Util::check_regex($regex);
#   if ($err) {
#     Util::error($err);
#   } else {
#     @res = $Config{_repository}->list($regex eq 'all' ? "." : $regex);
#     foreach my $found (@res) {
#       print GREEN, $found->name, RESET, " ".$found->location."\n";
#     }

#   }
# }


1;
