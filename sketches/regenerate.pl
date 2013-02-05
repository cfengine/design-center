#!/usr/bin/perl

use warnings;
use strict;

use JSON;
use File::Basename;
use File::Slurp;
use File::Find;

my @todo;
find(\&wanted, '.');

sub wanted
{
 push @todo, $File::Find::name if $_ eq 'sketch.json';
}

foreach my $f (@todo)
{
 my $d = dirname($f);
 $d =~ s,^\./,,;
 print $d, "\t";
 my $j = read_file($f);
 my $out = JSON->new()->relaxed()->utf8()->allow_nonref()->decode($j);
 print JSON->new()->utf8()->canonical()->encode($out), "\n";
}
