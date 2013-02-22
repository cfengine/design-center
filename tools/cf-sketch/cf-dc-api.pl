#!/usr/bin/perl

BEGIN
{
 if (-l $0)
 {
  require FindBin;
  $0 = readlink $0;
  FindBin->again();
 }
}

use File::Basename;
use FindBin;
use lib "$FindBin::Bin/perl-lib",
 "$FindBin::Bin/perl-lib/File-Which-1.09/lib",
 "$FindBin::Bin/perl-lib/JSON-2.53/lib",
 "$FindBin::Bin/perl-lib/Mo-0.31/lib";

use warnings;
use strict;
use DCAPI;
use Util;

$| = 1;                         # autoflush

my $base = basename($0);
my @log;

my $required_version = '3.4.3';
my $api = DCAPI->new();

unless ($api->curl())
{
 $api->exit_error("$base: could not locate `curl' executable in $ENV{PATH}");
}

unless ($api->cfagent())
{
 $api->exit_error("$base: could not locate `cf-agent' executable in $ENV{PATH} or /var/cfengine/bin");
}

unless (is_ok_cfengine_version($api->cfagent(), $required_version))
{
 $api->exit_error("$base: the `cf-agent' executable version is older than $required_version, sorry");
}

my $config_file = shift @ARGV;

unless ($config_file)
{
 $api->exit_error("Syntax: $base CONFIG_FILE [SERVICE_URL]");
}

my ($loaded, @errors) = $api->set_config($config_file);

unless ($loaded)
{
 $api->exit_error("$base could not load $config_file: [@errors]");
}

if (scalar @errors)
{
 $api->exit_error("$base startup errors", @errors);
}

my $data = $api->load(join '', <>);
my $debug = Util::hashref_search($data, qw/debug/);
my $version = Util::hashref_search($data, qw/dc_api_version/);
my $request = Util::hashref_search($data, qw/request/);
my $list = Util::hashref_search($request, qw/list/);
my $search = Util::hashref_search($request, qw/search/);
my $sketch_api = Util::hashref_search($request, qw/api/);
my $install = Util::hashref_search($request, qw/install/);
my $uninstall = Util::hashref_search($request, qw/uninstall/);

if ($debug)
{
 push @log, $api->data_dump();
}

unless (defined $version && $version eq $api->version())
{
 $api->exit_error("DC API Version not provided or mismatch " . $api->version(), @log);
}

unless (defined $request)
{
 $api->exit_error("No request provided.", @log);
}

if (defined $list)
{
 $api->ok({ data => { list => [$api->list($list)] }});
}
elsif (defined $search)
{
 $api->ok({ data => { search => [$api->search($search)] }});
}
elsif (defined $sketch_api)
{
 $api->ok({ data => { api => $api->sketch_api($sketch_api) }});
}
elsif (defined $install)
{
 my ($data, @warnings) = $api->install($install);

 $api->ok({ warnings => \@warnings, data => { install => $data }});
}
elsif (defined $uninstall)
{
 my ($data, @warnings) = $api->uninstall($uninstall);

 $api->ok({ warnings => \@warnings, data => { uninstall => $data }});
}
else
{
 push @log, "Nothing to do, but we're OK, thanks for asking.";
 $api->ok({ log => \@log,
            data => {} });
}

exit 0;

sub is_ok_cfengine_version
{
 my $bin = shift @_;
 my $req = shift @_;
 my $cfv = `$bin -V`;
 if ($cfv =~ m/\s+(\d+\.\d+\.\d+)/)
 {
  return $1 ge $req;
 }

 return 0;
}
