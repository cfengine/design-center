#!/usr/bin/perl

use warnings;
use strict;
use Test;

BEGIN { plan tests => 6, todo => [] }

ok(exists $ENV{CFPROMISES} && -x $ENV{CFPROMISES}, 1, "check for cf-promises");
ok(exists $ENV{CFAGENT} && -x $ENV{CFAGENT}, 1, "check for cf-agent");

ok(system($ENV{CFPROMISES}, -f => './test.cf'), 0, "syntax check test.cf");

open my $run, '-|', "$ENV{CFAGENT} -KI -f ./test.cf";

ok(defined $run, 1, "run status of test.cf");

my $output = join '', <$run>;

ok($output,
   qr/R: cfdc_memcached:server: Applications::Memcached/,
   "metadata check");

ok($output,
   qr/Overriding bundle return status to success/,
   "test mode override of bundle install status");
