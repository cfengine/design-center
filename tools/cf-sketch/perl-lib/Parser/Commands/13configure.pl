#
# configure/activate command
#
# CFEngine AS, October 2012
#
# Time-stamp: <2012-10-09 11:26:27 a10022>

use Term::ANSIColor qw(:constants);

use Util;
use DesignCenter::Config;

######################################################################

%COMMANDS =
  (
   'configure' =>
   [
    [
     'configure SKETCH [FILE.json]',
     'Configure the given sketch using the parameters from FILE.json or interactively if the file is ommitted.',
     '(\S+)\s+(\S+)',
     'configure_file'
    ],
    [
     '-configure SKETCH',
     'Configure the given sketch interactively.',
     '(\S+)',
     'configure_interactive'
    ],
   ]
  );

######################################################################

sub find_sketch {
  my $sketch = shift;
  my $res=DesignCenter::Config->_system->list(["."]);
  unless (exists($res->{$sketch})) {
    Util::error "Sketch $sketch is not installed, please use the 'install' command first.\n";
    return undef;
  }
  return $res->{$sketch}
}

sub command_configure_file {
  my $sketch = shift;
  my $file = shift;

  my $skobj = find_sketch($sketch) || return;
  $skobj->configure_with_file($file);
}

sub command_configure_interactive {
  my $sketch = shift;

  my $skobj = find_sketch($sketch) || return;
  $skobj->configure_interactive($file);
}
