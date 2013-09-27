#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "001 metadata check" => qr|___001_System_Sudoers_ensure: System::Sudoers license = MIT|,
            "002 metadata check" => qr|___002_System_Sudoers_ensure: System::Sudoers license = MIT|,
            "001 test mode" => qr| ___001_\w+: Leaving /tmp/tmp/sudoers.cfsketch.tmp in place in test mode|,
            "002 test mode" => qr| ___002_\w+: Leaving /tmp/tmp/sudoers.d/sample.sudoers.cfsketch.tmp in place in test mode|,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
