#
# list command for displaying installed sketches
#
# CFEngine AS, October 2012
# Time-stamp: <2012-10-09 23:36:55 a10022>

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
  $regex = "." if ($regex eq 'all' or !$regex);
  my $err = Util::check_regex($regex);
  if ($err) {
    Util::error($err);
  } else {
    my $res=DesignCenter::Config->_system->list([$regex]);
    my @res = sort keys %$res;
    if (@res) {
      my $id = 1;
      Util::output("The following sketches ".(($regex eq '.')?"are installed:":"match your query:")."\n\n");
      foreach my $found (@res) {
        print BOLD GREEN."$id. ".YELLOW."$found".RESET;
        if ($res->{$found}->entry_point) {
          my @activations = @{$res->{$found}->_activations};
          my $count = $res->{$found}->num_instances;
          if ($count) {
            print GREEN." (configured";
            if ($count > 1) {
              print ", $count instances";
            }
            print ")\n";
            if ($full) {
              my $activation_id=1;
              foreach my $activation (@activations) {
                my $act = $activation->{activated};
                my $active_str = ($act && $act ne '!any') ? GREEN."(Activated on '$act')" : RED."(Not activated)";
                print BOLD GREEN."\tInstance #$activation_id: $active_str".RESET."\n";
                print DesignCenter::JSON::pretty_print($activation, "\t\t", qr/^(prefix|class_prefix|activated)$/);
                $activation_id++;
              }
            }
          } else {
            print RED." (unconfigured)\n";
          }
        }
        else {
          print CYAN." (library)\n";
        }
        print RESET;
        $id++;
      }
      Util::output("\nUse list -v to show the activation parameters.\n") unless $full;
    }
    else {
      Util::error("No installed sketches match your query. Maybe use 'search' instead?\n");
    }
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
