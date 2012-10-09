#
# configure/activate command
#
# CFEngine AS, October 2012
#
# Time-stamp: <2012-10-09 02:32:00 a10022>

use Term::ANSIColor qw(:constants);

use Util;
use DesignCenter::Config;

######################################################################

%COMMANDS =
  (
   'configure' =>
   [
    [
     'configure SKETCH FILE.json',
     'Configure and activate the given sketch using the parameters from FILE.json.',
     '(\S+)\s+(\S+)',
     'configure_file'
    ],
   ]
  );

######################################################################

sub command_configure_file {
  my $sketch = shift;
  my $file = shift;

  my $res=DesignCenter::Config->_system->list(["."]);
  unless (exists($res->{$sketch})) {
    Util::error "Sketch $sketch is not installed, please use the 'install' command first.";
    return;
  }
  $res->{$sketch}->activate_with_file($file);
}
