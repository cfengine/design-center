#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check1" => qr/R: cfdc_php_fpm:server: Applications::PHP_FPM/,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
