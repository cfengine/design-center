#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check" => qr/R: cfdc_users:local: Users::Local/,
            "test user info1" => qr|Requested user tzz with GECOS 'Ted. Zlatanov' and UID/GID '10000/20000', living in './home./tzz' with shell './bin./bash' and password hash 'mypass'.  The group name is mygroup.|,
            "test user info2" => qr|pwentry for tzz is 'tzz:x:10000:20000:Ted. Zlatanov:./home./tzz:./bin./bash|,
            "test user info3" => qr|groupentry for tzz is 'mygroup:x:20000:|,
            "test user info4" => qr|shadowentry for tzz is 'tzz:mypass:\d+:0:99999:7:::|,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
