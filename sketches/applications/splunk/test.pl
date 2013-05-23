#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check 1" => qr/R: cfdc_splunk:install_forwarder: Applications::Splunk/,
            "installing" => qr/R: cfdc_splunk:install_forwarder: Installing the Splunk Forwarder with parameters/,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
