#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check" => qr/R: cfdc_stitch/,
            "badfilesname" => qr/Cannot create a relative filename 'badfilesname' - has no invariant meaning/,
            "everywhere line1" => qr/Data to insert in badfilesname: 'everywhere line'/,
            "everywhere line2" => qr,Data to insert in /tmp/stitched.txt: 'everywhere line,,
            "return empty" => qr/activation ___001_Data_Stitch_cfdc_stitch returned built = /,
            "return stitched" => qr,activation ___002_Data_Stitch_cfdc_stitch returned built = /tmp/stitched.txt,,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
