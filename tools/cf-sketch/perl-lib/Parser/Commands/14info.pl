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
  if ($regex eq '') {
    Util::warning "No query specified. If you want to view all sketches, please specify 'all'\n";
    return;
  }
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
      print "The following sketches match your query:\n";
      foreach my $found (@res) {
        $res->{$found}->load;
        $rec=$res->{$found}->metadata;
        print "\n";
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
              print GREEN."Yes".RESET;
              if ($count > 1) {
                print ", $count instances";
              }
              print "\n";
            } else {
              print RED."No\n".RESET;
            }
          }
        }
        if ($full) {
          if ($res->{$found}->entry_point) {
            my $ep = DesignCenter::Sketch::verify_entry_point($found, $res->{$found}->json_data);
            if ($ep && $ep->{varlist}) {
              print BLUE."Parameters:\n".RESET;
              for my $p (@{$ep->{varlist}}) {
                next if $p->{name} =~ /^(prefix|class_prefix|canon_prefix)$/;
                my $simple_type = $p->{type};
                $simple_type =~ s/\n+/ /gs;
                $simple_type =~ s/\s*:\s*/:/gs;
                my $def = (DesignCenter::JSON::recurse_print($p->{default}, undef, 1))[0]->{value};
                print BOLD BLUE."    $p->{name}".RESET.": $simple_type".($def ? " (default: $def)\n":"\n");
              }
            }
          }
        }
        print RESET;
        $id++;
      }
      Util::output("\nUse info -v to show the parameter information.\n") unless $full;
    }
    else {
      Util::error("No installed sketches match your query. Maybe use 'search' instead?\n");
    }
  }
}

1;
