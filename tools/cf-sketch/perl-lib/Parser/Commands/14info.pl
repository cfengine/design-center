#
# info: obtain information about a sketch
#
# CFEngine AS, May 2013

use Term::ANSIColor qw(:constants);

use Util;

######################################################################

%COMMANDS =
 (
  'info' =>
  [
   [
    'info [-v] REGEX | all',
    'Show detailed information about sketches that match the regular expression, use "all" to show all the sketches. Use -v to show even more details (parameter information).',
    '(?:(-v)\b\s*)?(\S*)',
   ],
  ]
 );

######################################################################

sub command_info {
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
        ($success, $result) = main::api_interaction({
                                                     describe => 1,
                                                     search => $regex,
                                                    });
        my $list = Util::hashref_search($result, 'data', 'search');
        my $first = 1;
        if (ref $list eq 'HASH')
        {
            # Get list of installed and activated sketches
            my $installed = main::get_installed;
            my $activs = main::get_activations;
            # If we have multiple repos, include repo names in the results
            my $multiple_repos = (keys %$list > 1);
            foreach my $repo (sort keys %$list)
            {
                foreach my $sketch (sort keys %{$list->{$repo}})
                {
                    if ($first)
                    {
                        print "The following sketches match your query:\n";
                        $first = undef;
                    }
                    my $meta = Util::hashref_search($list->{$repo}->{$sketch}, qw/metadata/);
                    my $api = Util::hashref_search($list->{$repo}->{$sketch}, qw/api/);
                    print "\n";
                    print BLUE."Sketch ".CYAN."$sketch\n".RESET;
                    print BLUE."Description: ".RESET.$meta->{description}."\n"
                     if $meta->{description};
                    print BLUE."Authors: ".RESET.join(", ", @{$meta->{authors}})."\n"
                     if $meta->{authors};
                    print BLUE."Version: ".RESET.$meta->{version}."\n"
                     if $meta->{version};
                    print BLUE."License: ".RESET.$meta->{license}."\n"
                     if $meta->{license};
                    print BLUE."Tags: ".RESET.join(", ", @{$meta->{tags}})."\n"
                     if $meta->{tags};
                    print BLUE."Installed: ".RESET.(exists($installed->{$sketch}) ? "Yes, under ".$installed->{$sketch} : "No")."\n";
                    print BLUE."Library: ".RESET."Yes\n" unless scalar(keys %$api);
                    if (scalar(keys %$api))
                    {
                        my $num_act = scalar(@{$activs->{$sketch}});
                        my $word = $num_act > 1 ? "instances" : "instance";
                        print BLUE."Activated: ".RESET.($num_act ? "Yes, $num_act $word" : "No")."\n";
                    }
                    if ($full && scalar(keys %$api))
                    {
                        print BLUE."Parameters:\n".RESET;
                        foreach my $bundle (sort keys %$api)
                        {
                            print "  For bundle ".CYAN.$bundle.RESET."\n";
                            foreach my $p (@{$api->{$bundle}})
                            {
                                print YELLOW."    ".$p->{name}.RESET.": ".$p->{type}."\n"
                                 unless $p->{type} =~ /^(metadata|environment)$/;
                            }
                        }
                    }
                }
            }
            Util::output("\nUse info -v to show the parameter information.\n") unless $full;
        }
        else
        {
            Util::error("Internal error: The API 'search' command returned an unknown data structure.");
        }
    }
}

# # TODO: FIX dependency printing
# #        print BLUE."Dependencies: ".RESET.join(", ", map { $_->{value} } DesignCenter::JSON::recurse_print($rec->{depends}, undef, 1))."\n"
# #          if $rec->{depends};
#         print RESET;
#         $id++;
#       }
#       Util::output("\nUse info -v to show the parameter information.\n") unless $full;
#     }
#     else {
#       Util::error("No installed sketches match your query. Maybe use 'search' instead?\n");
#     }
#   }
# }

1;
