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
    'deactivate SKETCH|ACTIVATION_ID|all ...',
    'Remove the given activations. If the sketch name is specified, all its activations are removed. If an activation ID is specified, only that activation is removed. If "all" is given, all activations are removed.',
    '(.+)?',
   ],
  ],
  'remove' =>
  [
   [
    'remove params PARAMSET|all ...',
    'Undefine the given parameter sets. Use "all" to remove all of them.',
    'param\S*\s+(.*)',
    'remove_params',
   ],
   [
    'remove environment ENV_NAME|all ...',
    'Undefine the given environment. Use "all" to remove all of them.',
    'env\S*\s+(.*)',
    'remove_envs',
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
        main::api_interaction({deactivate => ($s eq 'all') ? 1 : $s});
        Util::success("Deactivated $s.\n");
    }
}

sub command_remove_params {
    my $params = shift;
    my $defs = main::get_definitions;
    my $todo;
    if ($params eq 'all')
    {
        $todo = [ keys(%$defs) ];
    }
    else
    {
        my @params = split ' ', $params;
        foreach (@params)
        {
            Util::error("Param set '$_' does not exist.\n")
               unless exists($defs->{$_});
        }
        $todo = \@params;
    }
    my ($success, $result) = main::api_interaction({ undefine => $todo });
}

sub command_remove_envs {
    my $params = shift;
    my $envs = main::get_environments;
    my $todo;
    if ($params eq 'all')
    {
        $todo = [ keys(%$envs) ];
    }
    else
    {
        my @params = split ' ', $params;
        foreach (@params)
        {
            Util::error("Param set '$_' does not exist.\n")
               unless exists($envs->{$_});
        }
        $todo = \@params;
    }
    my ($success, $result) = main::api_interaction({ undefine_environment => $todo });
}

1;
