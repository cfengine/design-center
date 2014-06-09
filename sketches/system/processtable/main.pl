use warnings;
use strict;

use Proc::ProcessTable;
use FindBin;
use lib "$FindBin::Bin/../../sketch_template";
use dc;

sub find_processes
{
    my ($environment, $metadata, $regex) = @_;

    my $t = new Proc::ProcessTable;
    my @present;

    # there is no equivalent to this in CFEngine: find all processes whose full
    # command line matches a regular expression and collect *all* the available
    # fields for this particular platform
    foreach my $p ( @{$t->table} )
    {
        next unless $p->cmndline =~ m/$regex/;

        my %process;
        push @present, \%process;
        foreach ($t->fields)
        {
            $process{$_} = $p->{$_};
        }
    }

    return dc::module($metadata, { present => \@present });
}

dc::init();

exit 0;
