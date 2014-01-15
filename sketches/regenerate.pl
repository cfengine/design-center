#!/usr/bin/perl

use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/perl-lib", "$FindBin::Bin/perl-lib/File-Which-1.09/lib", "$FindBin::Bin/perl-lib/JSON-2.53/lib";

use JSON::PP;
use File::Basename;
use File::Find;

my @todo;
find(\&wanted, '.');

sub wanted
{
 push @todo, $File::Find::name if $_ eq 'sketch.json';
}

foreach my $f (@todo)
{
 print STDERR "Checking $f\n";
 my $d = dirname($f);
 $d =~ s,^\./,,;
 print $d, "\t";
 my $j = read_file($f);
 my $out = JSON::PP->new()->allow_barekey()->relaxed()->utf8()->allow_nonref()->decode($j);
 $out->{api} = {} unless exists $out->{api};
 print JSON::PP->new()->utf8()->canonical()->encode($out), "\n";
}

sub read_file
{
    my $f = shift;
    open my $fh, '<', $f or warn "Couldn't open $f: $!";
    return join('', <$fh>);
}
