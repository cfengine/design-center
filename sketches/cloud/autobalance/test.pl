#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check 1" => qr/R: cfdc_cloud:autobalance: Cloud::Autobalance/,
            "ec2 count" => qr/EC2 goal: \d+ cfworker/,
            "openstack count" => qr/OpenStack goal: \d+ cfworker/,
            "know thresholds" => qr/We know about thresholds/,
            "know EC2 options" => qr/We have ec2 option/,
            "know OpenStack options" => qr/We have openstack option/,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
