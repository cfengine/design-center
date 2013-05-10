#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check" => qr/R: cfdc_memcached:server: Applications::Memcached/,
            "test mode override of bundle install status" => qr/Overriding bundle return status to success/,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
