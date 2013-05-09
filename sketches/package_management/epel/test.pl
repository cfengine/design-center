#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $output = dctest::setup('./test.cf', 0);

# requires RH/CentOS, will not run on other platforms
