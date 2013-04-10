# Time-stamp: <2013-04-08 01:51:46 a10022>
#
# search command for searching through sketch list
# Diego Zamboni, October 1st, 2012.
# diego.zamboni@cfengine.com

use Term::ANSIColor qw(:constants);

use DesignCenter::Config;

%COMMANDS =
 (
  'search' =>
  [[
    'search [REGEX | all]',
    'Search sketch repository, use "all" to list everything.',
    '(.*)'
   ]]
 );

######################################################################

sub command_search {
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
                                               search => $regex,
                                              });
        my $list = Util::hashref_search($result, 'data', 'search');
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
                    Util::output("The following sketches ".(($regex eq '.')?"are available":"match your query").($multiple_repos?" in repository $repo":"").":\n\n");
                    foreach my $name (sort keys %found)
                    {
                        print RESET, GREEN, $name, RESET, " ".$found{$name}."\n";
                    }
                }
                else
                {
                    Util::error("No sketches match your query.\n");
                }
            }
        }
    }
}

1;
