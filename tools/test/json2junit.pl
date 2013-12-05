#!/usr/bin/perl

use warnings;
use strict;
use JSON;
use lib '../cf-sketch/perl-lib';

use Util;

my $coder = JSON->new()->allow_barekey()->relaxed()->utf8()->allow_nonref();

my $input = join('', <>);

my $out = $coder->decode($input);

my $result = Util::hashref_search($out, 'api_ok');

my $data = Util::hashref_search($result, 'data');

die "Design Center self-tests had no data"
    unless $data;

my $data = Util::hashref_search($result, 'data');

die "Design Center self-tests had no data"
    unless $data;

my $total = Util::hashref_search($data, 'tests_total');
my $passed = Util::hashref_search($data, 'tests_passed');

print '<?xml version="1.0" ?>', "\n";
printf '<testsuite errors="0" failures="%d" name="DC API self-test" tests="%d">',
    $total - $passed,
    $total;
print "\n";

my $results = Util::hashref_search($data, 'results');

die "Design Center self-tests had no valid results"
    unless ref $results eq 'ARRAY';

my %offsets;

foreach my $r (@$results)
{
    my $name = Util::hashref_search($r, 'test');
    $offsets{$name}++;
    printf '<testcase name="%s %d">', $name, $offsets{$name};
    print "\n";

    unless (Util::hashref_search($r, 'subtest_success'))
    {
        print '<failure>test failed</failure>';
        print "\n";
    }

    print "</testcase>\n";
}

print "</testsuite>\n";
