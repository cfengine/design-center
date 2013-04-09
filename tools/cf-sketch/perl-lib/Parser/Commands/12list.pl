#
# list command for displaying installed sketches
#
# CFEngine AS, October 2012
# Time-stamp: <2013-04-09 01:32:37 a10022>

use Term::ANSIColor qw(:constants);
use DesignCenter::JSON;
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
    'list [-v] params [REGEX]',
    'List defined parameter sets. If REGEX is given, only list sets that match it (either in the set name or the sketch name to which they correspond). Use -v to show the values in each parameter set.',
    '(?:(-v)\b\s*)?param\S*(?:\s+(.*))?',
    'listparams',
   ],
   [
    'list [sketches] [REGEX|all]',
    'List installed sketches. Specify REGEX to filter, no argument or "all" to list everything.',
    '(?:sketch\S*\b\s*)?(.*)',
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
        else
        {
            Util::error("Internal error: The API 'list' command returned an unknown data structure.");
        }
    }
}

sub command_listparams
{
    my $full=shift;
    my $regex=shift;
    $regex = "." if ($regex eq 'all' or !$regex);
    my $err = Util::check_regex($regex);
    if ($err)
    {
        Util::error($err);
    }
    else
    {
        my ($success, $result) = main::api_interaction({ definitions => 1 });
        my $list = Util::hashref_search($result, 'data', 'definitions');
        if (ref $list eq 'HASH')
        {
            my %found = ();
            foreach my $param (sort keys %$list)
            {
                my @sketches = sort keys %{$list->{$param}};
                $found{$param} = [ @sketches ] if ($param =~ /$regex/i || grep(/$regex/i, @sketches));
            }
            if (keys %found)
            {
                Util::output("The following parameter sets".(($regex eq '.')?" are defined":" match your query").":\n\n");
                foreach my $name (sort keys %found)
                {
                    my @sketches = @{$found{$name}};
                    my $word = (scalar(@sketches)>1 ? "Sketches" : "Sketch");
                    print RESET, GREEN, $name, RESET, ": $word ".join(", ", @sketches)."\n";
                    if ($full)
                    {
                        print DesignCenter::JSON::pretty_print_json($list->{$name})."\n";
                    }
                }
            }
        }
        else
        {
            Util::error("Internal error: The API 'definitions' command returned an unknown data structure.");
        }
    }
}
1;
