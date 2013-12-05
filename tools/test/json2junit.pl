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


__DATA__
         "results": [{
                "test": "deactivate all activations",
                "subtest_success": true,
                "subtest": {
                    "expected": {
                        "success": true
                    },
                    "command": {
                        "deactivate": true
                    }
                },
                "log": [
                    ["DCAPI::log3(DCAPI.pm:426): ", "Testing: command %s, expected %s", "{\"deactivate\":true}", "{\"success\":true}"],
                    ["DCAPI::log(DCAPI.pm:1593): ", "Deactivating all activations: %s", "{\"VCS::vcs_mirror\":[{\"params\":[\"vcs_base\",\"git_mirror_core\"],\"environment\":\"testing\"},{\"params\":[\"vcs_base\",\"svn_mirror_thrift\"],\"environment\":\"testing\"}]}"],
                    ["DCAPI::log(DCAPI.pm:242): ", "Saving vardata file /home/tzz/.cfagent/vardata.conf"],
                    ["DCAPI::log4(DCAPI.pm:440): ", "Result '%s': '%s', expected '%s'", "success", true, true]],
                "result": {
                    "api_ok": {
                        "warnings": [],
                        "success": true,
                        "errors": [],
                        "error_tags": {},
                        "data": {
                            "deactivate": {
                                "VCS::vcs_mirror": 1
                            }
                        },
                        "log": [],
                        "tags": {
                            "deactivate": 1
                        }
                    }
                }
            },


<?xml version="1.0" ?>
<testsuite errors="0" failures="0" name="my test suite" tests="1">
    <testcase classname="some.class.name" name="Test1" time="123.345000">
<failure type="junit.framework.AssertionFailedError">junit.framework.AssertionFailedError: 
        at tests.ATest.fail(ATest.java:9)
</failure>
        <system-out>
            I am stdout!
        </system-out>
        <system-err>
            I am stderr!
        </system-err>
    </testcase>
</testsuite>
