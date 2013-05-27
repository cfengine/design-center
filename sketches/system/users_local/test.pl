#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
            "metadata check1" => qr/R: cfdc_users:local: Users::Local/,
            "metadata check2" => qr/R: cfdc_users:runbased: Users::Local/,
            "test user info1" => qr|Requested user tzz with GECOS 'Ted Zlatanov' and UID/GID '10000/20000', living in '/home/tzz' with shell '/bin/bash' and password hash 'mypass'.  The group name is mygroup.|,
            "test user info2" => qr|Requested user tzz2 with GECOS 'Ted Zlatanov 2' and UID/GID '10001/20001', living in '/home/tzz2' with shell '/bin/bash' and password hash 'mypass2'.  The group name is mygroup.|,
            "test user info2" => qr|pwentry for tzz is 'tzz:x:10000:20000:Ted Zlatanov:/home/tzz:/bin/bash|,
            "test user info3" => qr|groupentry for tzz is 'mygroup:x:20000:|,
            "test user info4" => qr|shadowentry for tzz is 'tzz:mypass:\d+:0:99999:7:::|,
            # let's assume there is no tzz2 user in the world, OK?
            "runbased" => qr|tzz2 was missing|,
            "runbased2" => qr|/usr/sbin/useradd -d /home/tzz2 -c Ted Zlatanov 2 -g 20001 -m -p mypass2 -s /bin/bash -u 10001 tzz2|,
           };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
