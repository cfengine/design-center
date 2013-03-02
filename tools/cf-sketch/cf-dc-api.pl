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

my $required_version = '3.4.0';
my $api = DCAPI->new(cfengine_min_version => $required_version);

unless ($api->curl())
{
    $api->exit_error("$base: could not locate `curl' executable in $ENV{PATH}");
}

unless ($api->cfagent())
{
    $api->exit_error("$base: could not locate `cf-agent' executable in $ENV{PATH} or /var/cfengine/bin");
}

unless ($api->is_ok_cfengine_version())
{
    $api->exit_error("$base: the `cf-agent' executable version is before $required_version, sorry");
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
my $describe = Util::hashref_search($request, qw/describe/);

my $install = Util::hashref_search($request, qw/install/);
my $uninstall = Util::hashref_search($request, qw/uninstall/);

my $define = Util::hashref_search($request, qw/define/);
my $undefine = Util::hashref_search($request, qw/undefine/);
my $definitions = Util::hashref_search($request, qw/definitions/);

my $define_environment = Util::hashref_search($request, qw/define_environment/);
my $undefine_environment = Util::hashref_search($request, qw/undefine_environment/);
my $environments = Util::hashref_search($request, qw/environments/);

my $activate = Util::hashref_search($request, qw/activate/);
my $deactivate = Util::hashref_search($request, qw/deactivate/);
my $activations = Util::hashref_search($request, qw/activations/);

my $regenerate = Util::hashref_search($request, qw/regenerate/);

if ($debug)
{
    push @log, $api->data_dump();
}

unless (defined $version && $version eq $api->version())
{
    $api->exit_error("Broken JSON, or DC API Version not provided or mismatch: " . $api->version() . " vs. " . $version , @log);
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
elsif (defined $describe)
{
    $api->ok({ data => { describe => $api->describe($describe) }});
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
elsif (defined $activations)
{
    my ($data, @warnings) = $api->activations();

    $api->ok({ warnings => \@warnings, data => { activations => $data }});
}
elsif (defined $activate)
{
    my ($data, @warnings) = $api->activate($activate);

    $api->ok({ warnings => \@warnings, data => { activate => $data }});
}
elsif (defined $deactivate)
{
    my ($data, @warnings) = $api->deactivate($deactivate);

    $api->ok({ warnings => \@warnings, data => { deactivate => $data }});
}
elsif (defined $definitions)
{
    my ($data, @warnings) = $api->definitions();

    $api->ok({ warnings => \@warnings, data => { definitions => $data }});
}
elsif (defined $define)
{
    my ($data, @warnings) = $api->define($define);

    $api->ok({ warnings => \@warnings, data => { define => $data }});
}
elsif (defined $undefine)
{
    my ($data, @warnings) = $api->undefine($undefine);

    $api->ok({ warnings => \@warnings, data => { undefine => $data }});
}
elsif (defined $environments)
{
    my ($data, @warnings) = $api->environments();

    $api->ok({ warnings => \@warnings, data => { environments => $data }});
}
elsif (defined $define_environment)
{
    my ($data, @warnings) = $api->define_environment($define_environment);

    $api->ok({ warnings => \@warnings, data => { define_environment => $data }});
}
elsif (defined $undefine_environment)
{
    my ($data, @warnings) = $api->undefine_environment($undefine_environment);

    $api->ok({ warnings => \@warnings, data => { undefine_environment => $data }});
}
elsif (defined $regenerate)
{
    my ($data, @warnings) = $api->regenerate($regenerate);

    $api->ok({ warnings => \@warnings, data => { regenerate => $data }});
}
else
{
    push @log, "Nothing to do, but we're OK, thanks for asking.";
    $api->ok({ log => \@log,
               data => {} });
}

exit 0;
