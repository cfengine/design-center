#
# list command for displaying installed sketches
#
# CFEngine AS, October 2012
# Time-stamp: <2012-10-09 00:05:04 a10022>

use Term::ANSIColor qw(:constants);

use Util;
use DesignCenter::Config;

######################################################################

%COMMANDS =
  (
   'list' =>
   [
    [
     '-list activations',
     'List activated sketches, with their parameters.',
     'activations',
     'listactivations',
    ],
    [
     'list [REGEX|all]',
     'List installed sketches. Specify REGEX to filter, no argument or "all" to list everything.',
     '(.*)'
    ],
   ]
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

sub command_listactivations {
  my $activations = DesignCenter::Config->_system->activations;

  my $activation_id = 1;
  foreach my $sketch (sort keys %$activations) {
    if ('HASH' eq ref $activations->{$sketch}) {
      Util::color_warn "Skipping unusable activations for sketch $sketch!";
      next;
    }

    foreach my $activation (@{$activations->{$sketch}}) {
      print BOLD GREEN."$activation_id\t".YELLOW."$sketch".RESET,
        DesignCenter::JSON->coder->encode($activation),
            "\n";

      $activation_id++;
    }
  }
}
