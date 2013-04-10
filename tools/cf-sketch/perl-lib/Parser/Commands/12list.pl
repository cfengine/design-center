#
# list command for displaying installed sketches
#
# CFEngine AS, October 2012
# Time-stamp: <2013-04-10 02:36:44 a10022>

use Term::ANSIColor qw(:constants);
use DesignCenter::JSON;
use Util;

######################################################################

%COMMANDS =
 (
  'list' =>
  [
   # [
   #  'list [-v] [REGEX|all]',
   #  'List installed sketches and their configuration status. Specify REGEX to filter, no argument or "all" to list everything, use -v to show full configuration details.',
   #  '(?:(-v)\b\s*)?(.*)',
   #  'list',
   # ],
   [
    '-list [-v] activations [REGEX|all]',
    'List defined activations. Use -v to show the details of each activation.',
    '(?:(-v)\b\s*)?act\S*(?:\s+(.*))?',
    'list_activations',
   ],
   [
    '-list [-v] params [REGEX|all]',
    'List defined parameter sets. If REGEX is given, only list sets that match it (either in the set name or the sketch name to which they correspond). Use -v to show the values in each parameter set.',
    '(?:(-v)\b\s*)?param\S*(?:\s+(.*))?',
    'list_params',
   ],
   [
    '-list [-v] environments [REGEX|all]',
    'List defined environments. If REGEX is given, only list environments that match it. Use -v to show the full environment definition.',
    '(?:(-v)\b\s*)?env\S*(?:\s+(.*))?',
    'list_envs',
   ],
   [
    'list [-v] [sketches|params|activations|environments] [REGEX|all]',
    'List defined sketches, parameter sets, activations or environments (sketches is the default). If REGEX is given, only list those that match it. Use -v to show detailed information.',
    '(?:(-v)\b\s*)?(?:sketch\S*\b\s*)?(.*)',
    'list_sketches',
   ],
  ]
 );

######################################################################

sub command_list_sketches {
    my $full=shift;
    my $regex=shift;

    return unless $regex = Util::validate_and_set_regex($regex);

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

sub command_list_params
{
    my $full=shift;
    my $regex=shift;

    return unless $regex = Util::validate_and_set_regex($regex);

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

sub command_list_activations
{
    my $full = shift;
    my $regex = shift;

    return unless $regex = Util::validate_and_set_regex($regex);

    my ($success, $result) = main::api_interaction({ activations => 1 });
    my $activs = Util::hashref_search($result, 'data', 'activations');
    if (ref $activs eq 'HASH')
    {
        my $printed = undef;
        foreach my $sketch (keys %$activs)
        {
            next unless $sketch =~ /$regex/i;
            foreach my $a (@{$activs->{$sketch}})
            {
                unless ($printed)
                {
                    Util::output("The following ".(($regex eq '.')?"activations are defined":"activations match your query").":\n\n");
                }
                $printed = 1;
                print RESET, GREEN, $sketch, RESET, ": Parameter sets [ ".join(", ", @{$a->{params}})." ] on environment '".$a->{environment}."'\n";
                if ($full)
                {
                    print DesignCenter::JSON::pretty_print_json($a)."\n";
                }
            }
        }
        Util::warning("No activations ".(($regex eq '.')?"are defined.\n" : "match your query\n")) unless $printed;
    }
    else
    {
        Util::error("Internal error: The API 'activations' command returned an unknown data structure.");
    }
}

sub command_list_envs
{
    my $full = shift;
    my $regex = shift;
    return unless $regex = Util::validate_and_set_regex($regex);

    my ($success, $result) = main::api_interaction({ environments => 1 });
    my $envs = Util::hashref_search($result, 'data', 'environments');
    if (ref $envs eq 'HASH')
    {
        my $printed = undef;
        foreach my $env (keys %$envs)
        {
            next unless $env =~ /$regex/i;
            unless ($printed)
            {
                Util::output("The following ".(($regex eq '.')?"environments are defined":"environments match your query").":\n\n");
            }
            $printed = 1;
            print RESET, GREEN, $env, RESET, "\n";
            if ($full)
            {
                print DesignCenter::JSON::pretty_print_json($envs->{$env})."\n";
            }
        }
        Util::warning("No environments ".(($regex eq '.')?"are defined.\n" : "match your query\n")) unless $printed;
    }
}

1;
