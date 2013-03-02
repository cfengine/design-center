#!/usr/bin/perl

use File::Basename;
use warnings;
use strict;

my %handlers = (
                cf => 'cfengine3-mode',
                pl => 'cperl-mode',
                pm => 'cperl-mode',
                sh => 'shell-mode',
               );

foreach my $f (@ARGV)
{
    next unless -f $f;
    my ($name,$path,$suffix) = fileparse($f, keys %handlers);

    if (exists $handlers{$suffix})
    {
        print "Reindenting $f\n";
        system(emacs => '--batch',
               '--eval' => "(setq enable-local-variables :all)",
               '--visit' => $f,
               '--eval' => "($handlers{$suffix})",
               '--eval' => "(hack-local-variables)",
               '--eval' => '(indent-region (point-min) (point-max) nil)',
               '--eval' => '(save-some-buffers t)');
    }
    else
    {
        warn "Sorry, can't handle file extension of $f";
    }
}
