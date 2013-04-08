# Time-stamp: <2013-04-08 02:14:09 a10022>
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

sub command_install
{
    my $sketchstr = shift;
    my $sketches = [ split /[,\s]+/, $sketchstr ];
    DesignCenter::Config->_repository->install($sketches)
}

1;
