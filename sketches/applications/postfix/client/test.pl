#!/usr/bin/perl

use warnings;
use strict;

use lib "../../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check1" => qr/R: cfdc_postfix:client: Applications::Postfix::Client/,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
