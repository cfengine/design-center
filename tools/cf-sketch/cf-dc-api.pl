#!/usr/bin/perl

BEGIN
{
    $ENV{PERL_JSON_BACKEND} = 'JSON::backportPP';

    if (-l $0)
    {
        require FindBin;
        $0 = readlink $0;
        FindBin->again();
    }
}

use File::Basename;
use FindBin;
use lib map { $_,
               "$_/File-Which-1.09/lib",
               "$_/File-Path-2.09",
               "$_/JSON-2.53/lib",
               "$_/Mo-0.31/lib" }
 ("$FindBin::Bin/perl-lib", "$FindBin::Bin/../lib/cf-sketch");

use warnings;
use strict;
use DCAPI;
use Util;

$| = 1;                         # autoflush

my $base = basename($0);
my @log;

my $required_version = '3.4.0';
my $api = DCAPI->new(cfengine_min_version => $required_version);

unless ($api->curl())
{
    $api->exit_error("$base: could not locate `curl' executable in $ENV{PATH}.  Install curl, please.");
}

unless ($api->cfagent())
{
    $api->exit_error("$base: You probably need to install CFEngine!  I could not locate `cf-agent' executable in $ENV{PATH} or /var/cfengine/bin");
}

unless ($api->is_ok_cfengine_version())
{
    $api->exit_error("$base: the `cf-agent' executable version is before $required_version, sorry.  You need to upgrade CFEngine!");
}

my $config_file = shift @ARGV;
my $data_file = shift @ARGV;

unless ($config_file)
{
    $api->exit_error("Syntax: $base CONFIG_FILE [DATA_FILE] [SERVICE_URL]");
}

my $config_result = $api->set_config($config_file);

unless ($config_result->success())
{
    $api->exit_error($config_result);
}

my $data = $api->load(defined $data_file ? $data_file : join('', <>));

my $result = $api->dispatch($data, \@log);

$result->out();

if ($ENV{NOIGNORE})
{
    exit ! $result->success();
}
else
{
    exit 0;
}
