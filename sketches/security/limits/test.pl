#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check 1" => qr/R: cfdc_security:limits: Security::security_limits/,
            "return OK" => qr,\Qreturned filename = /tmp/etc/security/limits.conf,,
            "test mode" => qr[\QSecurity limits policy in test mode, managing domains *],
            "option1: Empty First" => qr,\QEmpty First: disabled,,
            "option2: ensure present" => qr,\QMgmt Policy: ensure present,,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
