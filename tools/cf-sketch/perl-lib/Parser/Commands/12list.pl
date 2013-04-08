#
# list command for displaying installed sketches
#
# CFEngine AS, October 2012
# Time-stamp: <2013-04-08 03:26:26 a10022>

use Term::ANSIColor qw(:constants);

use Util;

######################################################################

%COMMANDS =
 (
  'list' =>
  [
   # [
   #  '-list activations',
   #  'List activated sketches, with their parameters.',
   #  'activations',
   #  'listactivations',
   # ],
   # [
   #  'list [-v] [REGEX|all]',
   #  'List installed sketches and their configuration status. Specify REGEX to filter, no argument or "all" to list everything, use -v to show full configuration details.',
   #  '(?:(-v)\b\s*)?(.*)',
   #  'list',
   # ],
   [
    'list [REGEX|all]',
    'List installed sketches. Specify REGEX to filter, no argument or "all" to list everything.',
    '(.*)',
    'list',
   ],
  ]
 );

######################################################################

sub command_list {
    my $regex=shift;
    $regex = "." if ($regex eq 'all' or !$regex);
    my $err = Util::check_regex($regex);
    if ($err)
    {
        Util::error($err);
    }
    else
    {
        ($success, $result) = main::api_interaction({
                                               describe => 1,
                                               list => $regex,
                                              });
        my $list = Util::hashref_search($result, 'data', 'list');
        if (ref $list eq 'HASH')
        {
            # If we have multiple repos, include repo names in the results
            my $multiple_repos = (keys %$list > 1);
            foreach my $repo (sort keys %$list)
            {
                my %found = ();
                foreach my $sketch (values %{$list->{$repo}})
                {
                    my $name = Util::hashref_search($sketch, qw/metadata name/);
                    my $desc = Util::hashref_search($sketch, qw/metadata description/);
                    $found{$name} = $desc || "(no description found)";
                }
                if (keys %found)
                {
                    Util::output("The following ".(($regex eq '.')?"sketches are installed":"installed sketches match your query").($multiple_repos?" in repository $repo":"").":\n\n");
                    foreach my $name (sort keys %found)
                    {
                        print RESET, GREEN, $name, RESET, " ".$found{$name}."\n";
                    }
                }
                else
                {
                    Util::error("No sketches ".(($regex eq '.')?"are installed":"match your query").". Maybe use 'search' instead?\n");
                }
            }
        }
    }
}

1;
