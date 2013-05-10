#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check" => qr/R: cfdc_packages:installed: Packages::installed/,
            "test mode operation 1" => qr/In test mode, so simulating adding package screen/,
            "test mode operation 2" => qr/In test mode, so simulating removing package nosuchpackage/,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
