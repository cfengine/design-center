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
  'uninstall' =>
  [
   [
    'uninstall SKETCH ...',
    'Uninstall the given sketches. All their activations are also removed.',
    '(.+)?',
   ],
  ],
  'deactivate' =>
  [
   [
    'deactivate SKETCH | ACTIVATION_ID ...',
    'Remove the given activations. If the sketch name is specified, all its activations are removed. If an activation ID is specified, only that activation is removed.',
    '(.+)?',
   ],
  ],
 );

######################################################################


sub command_uninstall {
    my $sketches = shift;
    my @sketches = split ' ', $sketches;
    my $installed = main::get_installed;
    my @todo = ();
    foreach my $s (@sketches)
    {
        if (exists($installed->{$s}))
        {
            push @todo,
            {
             sketch => $s, target => $Config{repolist}->[0],
            };
        }
        else
        {
            Util::error("Error: sketch '$s' is not installed.\n");
        }
    }
    # First deactivate them
    command_deactivate($sketches);
    my ($success, $result) = main::api_interaction({uninstall => \@todo });
    my $tags = Util::hashref_search($result, 'tags');
    foreach my $s (@sketches)
    {
        if ($tags->{$s})
        {
            Util::success("Sketch '$s' was uninstalled.\n");
        }
        else
        {
            Util::error("Sketch '$s' was not uninstalled.\n");
        }
    }
}

sub command_deactivate {
    my $activs = shift;
    my @activs = split ' ', $activs;
    foreach my $s (@activs)
    {
        main::api_interaction({deactivate => $s});
        Util::success("Deactivated $s.\n");
    }
}

1;
