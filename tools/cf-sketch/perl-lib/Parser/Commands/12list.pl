#
# list command for displaying installed sketches
#
# CFEngine AS, October 2012
# Time-stamp: <2012-10-09 01:19:49 a10022>

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
     'list [-v] [REGEX|all]',
     'List installed sketches and their configuration status. Specify REGEX to filter, no argument or "all" to list everything, use -v to show full configuration details.',
     '(?:(-v)\b\s*)?(.*)',
     'list',
    ],
   ]
  );

######################################################################

sub command_list {
  my $full=shift;
  my $regex=shift;
  my $err = Util::check_regex($regex);
  if ($err) {
    Util::error($err);
  } else {
    $res=DesignCenter::Config->_system->list([$regex eq 'all' ? "." : $regex]);
    my $id = 1;
    foreach my $found (sort keys %$res) {
      print BOLD GREEN."$id. ".YELLOW."$found".RESET;
      my @activations = @{$res->{$found}->{_activations}};
      if (@activations) {
        print GREEN." (configured";
        my $count=scalar(@activations);
        if ($count > 1) {
          print ", $count instances";
        }
        print ")\n";
        if ($full) {
          my $activation_id=1;
          foreach my $activation (@activations) {
            print BOLD GREEN."\tInstance #$activation_id: ".RESET,
              DesignCenter::JSON->coder->encode($activation), "\n";
            $activation_id++;
          }
        }
      }
      else {
        print RED." (unconfigured)\n";
      }
      print RESET;
#      print GREEN, "$found", RESET, " $res->{$found}->{fulldir}\n";
      $id++;
    }
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
