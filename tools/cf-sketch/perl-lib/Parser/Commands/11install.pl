# Time-stamp: <2013-06-22 01:38:09 a10022>
#
# search command for searching through sketch list
# Diego Zamboni, October 1st, 2012.
# diego.zamboni@cfengine.com

use Term::ANSIColor qw(:constants);

######################################################################

%COMMANDS =
  (
   'install' =>
   [[
     'install SKETCH ...',
     'Install or update the given sketches',
     '(.+)'
    ]]
  );

######################################################################

sub command_install
  {
    my $sketchstr = shift;
    my @sketches = split /[,\s]+/, $sketchstr;
    my @todo = map
      {
        {
          sketch => $_, force => $Config{force}, source => $Config{sourcedir},
            target => $Config{repolist}->[0],
          }
      } @sketches;
    my ($success, $result) = main::api_interaction({install => \@todo});
    Util::print_api_messages($result);
    my $installresult = Util::hashref_search($result, qw/data install/);
    if (ref $installresult eq 'HASH') {
      foreach my $repo (sort keys %$installresult) {
        foreach my $sketch (sort keys %{$installresult->{$repo}}) {
            # $installresult contains mixed files and sketches, so we
            # need to differentiate and print as appropriate. Files
            # are not printed unless verbose mode is on.
            if ($repo =~ m!/!)
            {
                Util::success("Sketch $sketch installed under $repo.\n");
            }
            else
            {
                Util::success("File $sketch installed as part of sketch $repo.\n")
                   if $Config{verbose};
            }
        }
      }
    }
  }

1;
