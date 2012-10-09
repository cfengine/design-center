#
# info: obtain information about a sketch
#
# CFEngine AS, October 2012

use Term::ANSIColor qw(:constants);

use Util;
use DesignCenter::Config;

######################################################################

%COMMANDS =
  (
   'info' =>
   [
    [
     'info SKETCH | REGEX | all',
     'Show detailed information about the given sketch, or those that match the regular expression, use "all" to show all the sketches.',
     '(\S+)',
    ],
   ]
  );

######################################################################


sub command_info {
  my $regex=shift;
  $regex = "." if ($regex eq 'all' or !$regex);
  my $err = Util::check_regex($regex);
  if ($err) {
    Util::error($err);
  } else {
    my $res=DesignCenter::Config->_repository->search($regex);
    my $installed=DesignCenter::Config->_system->list([$regex]);
    my @res = sort keys %$res;
    if (@res) {
      my $id = 1;
      foreach my $found (@res) {
        $res->{$found}->load;
        $rec=$res->{$found}->metadata;
        print BLUE."Sketch ".CYAN."$found\n".RESET;
        print BLUE."Description: ".RESET.$rec->{description}."\n"
          if $rec->{description};
        print BLUE."Authors: ".RESET.join(", ", @{$rec->{authors}})."\n"
          if $rec->{authors};
        print BLUE."Version: ".RESET.$rec->{version}."\n"
          if $rec->{version};
        print BLUE."License: ".RESET.$rec->{license}."\n"
          if $rec->{license};
        print BLUE."Tags: ".RESET.join(", ", @{$rec->{portfolio} or $rec->{tags}})."\n"
          if $rec->{portfolio} or $rec->{tags};
# TODO: FIX dependency printing
#        print BLUE."Dependencies: ".RESET.join(", ", map { $_->{value} } DesignCenter::JSON::recurse_print($rec->{depends}, undef, 1))."\n"
#          if $rec->{depends};
        print BLUE."Installed: ".RESET.(exists($installed->{$found}) ? "Yes, under ".$installed->{$found}->fulldir : "No")."\n";
        print BLUE."Library: ".RESET."Yes\n" unless ($res->{$found}->entry_point);
        if ($installed->{$found}) {
          if ($res->{$found}->entry_point) {
            my @activations = @{$installed->{$found}->_activations};
            my $count = $installed->{$found}->num_instances;
            print BLUE."Activated: ".RESET;
            if ($count) {
              print GREEN." Yes";
              if ($count > 1) {
                print ", $count instances";
              }
              print "\n";
            } else {
              print RED." No\n";
            }
          }
        }
        print "\n".RESET;
        $id++;
      }
    }
    else {
      Util::error("No installed sketches match your query. Maybe use 'search' instead?\n");
    }
  }
}

1;
