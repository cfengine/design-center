#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check" => qr/R: cfdc_etc_hosts:configure: System::etc_hosts/,
            "test mode override of bundle install status" => qr|R: activation __001_System_etc_hosts_configure returned file = /tmp/hosts|,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
