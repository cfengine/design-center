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
if ( "$FindBin::Bin" eq "/usr/local/bin" )
{
    use lib "/usr/local/lib/cf-sketch",
     "/usr/local/lib/cf-sketch/File-Which-1.09/lib",
     "/usr/local/lib/cf-sketch/JSON-2.53/lib",
     "/usr/local/lib/cf-sketch/Mo-0.31/lib";
} else {
    use lib "$FindBin::Bin/perl-lib",
     "$FindBin::Bin/perl-lib/File-Which-1.09/lib",
     "$FindBin::Bin/perl-lib/JSON-2.53/lib",
     "$FindBin::Bin/perl-lib/Mo-0.31/lib";
}

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

my $define_validation = Util::hashref_search($request, qw/define_validation/);
my $undefine_validation = Util::hashref_search($request, qw/undefine_validation/);
my $validations = Util::hashref_search($request, qw/validations/);
my $validate = Util::hashref_search($request, qw/validate/);

my $activate = Util::hashref_search($request, qw/activate/);
my $deactivate = Util::hashref_search($request, qw/deactivate/);
my $activations = Util::hashref_search($request, qw/activations/);

my $compose = Util::hashref_search($request, qw/compose/);
my $decompose = Util::hashref_search($request, qw/decompose/);
my $compositions = Util::hashref_search($request, qw/compositions/);

my $regenerate = Util::hashref_search($request, qw/regenerate/);

if ($debug)
{
    push @log, $api->data_dump();
}

unless (defined $version && $version eq $api->version())
{
    $api->exit_error("Broken JSON, or DC API Version not provided or mismatch: " . $api->version() . " vs. " . ($version||'???') , @log);
}

unless (defined $request)
{
    $api->exit_error("No request provided.", @log);
}

my $result;
if (defined $list)
{
    $result = $api->list($list, { describe => $describe});
}
elsif (defined $search)
{
    $result = $api->search($search, { describe => $describe});
}
elsif (defined $describe)
{
    $result = $api->describe($describe);
}
elsif (defined $install)
{
    $result = $api->install($install);
}
elsif (defined $uninstall)
{
    $result = $api->uninstall($uninstall);
}
elsif (defined $compositions)
{
    $result = DCAPI::Result->new(api => $api,
                                 status => 1,
                                 success => 1,
                                 data=> {compositions => $api->compositions()});
}
elsif (defined $compose)
{
    $result = $api->compose($compose);
}
elsif (defined $decompose)
{
    $result = $api->decompose($decompose);
}
elsif (defined $activations)
{
    $result = DCAPI::Result->new(api => $api,
                                 status => 1,
                                 success => 1,
                                 data=> {activations => $api->activations()});
}
elsif (defined $activate)
{
    $result = $api->activate($activate, { compose => $compose });
}
elsif (defined $deactivate)
{
    $result = $api->deactivate($deactivate);
}
elsif (defined $definitions)
{
    $result = DCAPI::Result->new(api => $api,
                                 status => 1,
                                 success => 1,
                                 data=> {definitions => $api->definitions()});
}
elsif (defined $define)
{
    $result = $api->define($define);
}
elsif (defined $undefine)
{
    $result = $api->undefine($undefine);
}
elsif (defined $environments)
{
    $result = DCAPI::Result->new(api => $api,
                                 status => 1,
                                 success => 1,
                                 data=> {environments => $api->environments()});
}
elsif (defined $define_environment)
{
    $result = $api->define_environment($define_environment);
}
elsif (defined $undefine_environment)
{
    $result = $api->undefine_environment($undefine_environment);
}
elsif (defined $validations)
{
    $result = DCAPI::Result->new(api => $api,
                                 status => 1,
                                 success => 1,
                                 data=> {validations => $api->validations()});
}
elsif (defined $define_validation)
{
    $result = $api->define_validation($define_validation);
}
elsif (defined $undefine_validation)
{
    $result = $api->undefine_validation($undefine_validation);
}
elsif (defined $validate)
{
    $result = $api->validate($validate);
}
elsif (defined $regenerate)
{
    $result = $api->regenerate($regenerate);
}
else
{
    $result = DCAPI::Result->new(api => $api,
                                 status => 1,
                                 success => 1,
                                 log => [ "Nothing to do, but we're OK, thanks for asking." ]);
}

$result->out();
exit 0;
