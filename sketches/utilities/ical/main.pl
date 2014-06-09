use warnings;
use strict;

use iCal::Parser;
use FindBin;
use lib "$FindBin::Bin/../../sketch_template";
use dc;

sub parse_ical
{
    my ($environment, $metadata, $file, $classes, $days_back, $days_forward) = @_;

    my $today = DateTime->now();
    # for Christmas testing
    # $today = DateTime->new(year => 2014, month => 12, day => 25)->truncate(to => "day");
    my $end = $today->clone();

    $today->subtract($days_back) if $days_back;
    $end->add(days => $days_forward) if $days_forward;

    my $parser = iCal::Parser->new(start => $today,
                                   end => $end);
    my $hash = $parser->parse($file);

    my @events;
    my $ehash = $hash->{events};
    foreach my $year (keys %$ehash)
    {
        foreach my $month (keys %{$ehash->{$year}})
        {
            foreach my $day (keys %{$ehash->{$year}->{$month}})
            {
                foreach my $ekey (keys %{$ehash->{$year}->{$month}->{$day}})
                {
                    my $event = $ehash->{$year}->{$month}->{$day}->{$ekey};
                    push @events, $event->{DESCRIPTION} if $event->{DESCRIPTION};
                    push @events, $event->{SUMMARY} if $event->{SUMMARY};
                }
            }
        }
    }

    my @classes = @events;
    push @classes, 'have_events' if scalar @events;

    return dc::module($metadata,
                      { events => \@events, todo => $hash->{todos}, },
                      $classes ? \@classes : [],
                      [qw/ical ics time_based events/]);
}

dc::init();

exit 0;
