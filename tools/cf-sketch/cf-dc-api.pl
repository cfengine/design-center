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

use FindBin;
use lib "$FindBin::Bin/perl-lib", "$FindBin::Bin/perl-lib/File-Which-1.09/lib", "$FindBin::Bin/perl-lib/JSON-2.53/lib";

use warnings;
use strict;
use DCAPI;
use Util;

$| = 1;                         # autoflush

my $api = DCAPI->new();

unless ($api->curl())
{
 api_exit_error("$0: could not locate `curl' executable in $ENV{PATH}");
}

my $config_file = shift @ARGV;

unless ($config_file)
{
 api_exit_error("Syntax: $0 CONFIG_FILE [SERVICE_URL]");
}

my ($config, @errors) = $api->config($config_file);

unless ($config)
{
 api_exit_error("$0 could not load $config_file");
}

my $data = $api->load(join '', <>);
my $version = Util::hashref_search($data, qw/dc-api-version/);
my $request = Util::hashref_search($data, qw/request/);
my $list = Util::hashref_search($request, qw/list/);
my $search = Util::hashref_search($request, qw/search/);

unless (defined $version && $version eq $api->version())
{
 $api->exit_error("DC API Version not provided or mismatch " . $api->version());
}

unless (defined $request)
{
 $api->exit_error("No request provided.");
}

if (defined $list)
{
 $api->exit_error("list not implemented yet");
 # api_ok({ data => { list => [] }});
}
elsif (defined $search)
{
 $api->exit_error("search not implemented yet");
 # api_ok({ data => { search => [] }});
}
else
{
 $api->ok({ log => ["Nothing to do, but we're OK, thanks for asking."],
          data => {} });
}

exit 0;
