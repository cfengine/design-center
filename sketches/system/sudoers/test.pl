#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check 1" => qr/R: cfdc_sudoers:ensure: System::Sudoers/,
            "test mode" => qr,Leaving /tmp/tmp/sudoers.cfsketch.tmp in place in test mode,,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
