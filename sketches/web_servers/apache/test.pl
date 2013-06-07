#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check" => qr/R: cfdc_webserver:apache/,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
