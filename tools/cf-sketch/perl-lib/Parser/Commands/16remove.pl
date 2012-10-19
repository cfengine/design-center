#
# remove command: remove both sketches and activations
#
# CFEngine AS, October 2012.

use Term::ANSIColor qw(:constants);

use Util;
use DesignCenter::Config;

######################################################################

%COMMANDS =
  (
   'remove' =>
   [
    [
     'remove sketch SKETCH ...',
     'Uninstall the given sketches. All their configurations are also removed.',
     'sketch\s+(.+)?',
     'remove_sketch',
    ],
    [
     'remove config SKETCH | SKETCH#NUM ...',
     'Remove the given configurations. If only the sketch name is specified, all its configurations are removed. If a number is specified, only that configuration instance is removed (numbers are as reported by "list -v").',
     'conf\S*\s+(.+)?',
     'remove_config',
    ],
   ],
  );

######################################################################


sub command_remove_sketch {
  my $sketches = shift;
  my @sketches = split ' ', $sketches;
  DesignCenter::Config->_system->remove(\@sketches);
}

sub command_remove_config {
  my $sketches = shift;
  my @sketches = split ' ', $sketches;
  foreach my $s (@sketches) {
    DesignCenter::Config->_system->deactivate($s);
  }
}

1;
