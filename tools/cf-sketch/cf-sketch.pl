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

my $inputs_root;
my $configdir;

BEGIN
{
  # Inputs directory depending on root/non-root/policy hub
  $inputs_root = $> != 0 ? glob("~/.cfagent/inputs") : (-e '/var/cfengine/state/am_policy_hub' ? '/var/cfengine/masterfiles' : '/var/cfengine/inputs');
  # Configuration directory depending on root/non-root
  $configdir = $> == 0 ? '/etc/cf-sketch' : glob('~/.cf-sketch');
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

# for encode/decode, not to use it directly!!!
my $dcapi = DCAPI->new(cfengine_min_version => 1);

use Getopt::Long;

my %options = (
               environment => 'cf_sketch_testing',
               repolist => [ "$inputs_root/sketches" ],
               activate => {},
               install => [],
               force => 0,
               verbose => 0,
               runfile => "$inputs_root/api-runfile.cf",
              );

Getopt::Long::Configure("bundling");

GetOptions(\%options,
           "expert!",
           "verbose|v!",
           "generate!",
           "force|f!",
           "installsource|is=s",
           "cfpath=s",
           "install|i=s@",
           "deactivate-all|da",
           "activate|a=s%",
           "runfile|rf=s",
           "repolist|rl=s@",
          );

die "$0: cf-sketch can only be used in --expert mode" unless $options{expert};

die "$0: --installsource DIR must be specified" unless $options{installsource};

my $sourcedir = dirname($options{installsource});
die "Sorry, can't locate source directory" unless -d $sourcedir;

api_interaction({
                 define_environment => {
                                        $options{environment} =>
                                        {
                                         activated => 1,
                                         test => 1,
                                         verbose => !!$options{verbose}
                                        }
                                       }
                });

if ($options{'deactivate-all'})
{
    api_interaction({deactivate => 1});
}

if (scalar @{$options{install}})
{
    my @todo = map
    {
        {
            sketch => $_,
            force => $options{force},
            source => $sourcedir,
            target => $options{repolist}->[0],
        }
    } @{$options{install}};
    api_interaction({install => \@todo});
}

if (scalar keys %{$options{activate}})
{
    my %todefine;
    foreach my $file (Util::uniq(values %{$options{activate}}))
    {
        $todefine{$file} = $dcapi->load($file);
        die "Could not load $file: $!" unless defined $todefine{$file};
    }

    api_interaction({define => \%todefine});

    my %todo = map
    {
        $_ => {
               target => $options{repolist}->[0],
               environment => $options{environment},
               params => [ $options{activate}->{$_} ],
              }
    } keys %{$options{activate}};

    api_interaction({activate => \%todo});
}

if ($options{'generate'})
{
    api_interaction({regenerate => 1});
}

sub api_interaction
{
    my $request = shift @_;

    my $mydir = dirname($0);
    my $api_bin = "$mydir/cf-dc-api.pl";
    open my $api, '|-', "$api_bin -" or die "Could not open $api_bin: $!";

    my $config = $dcapi->cencode({
                                  log => "STDERR",
                                  log_level => $options{verbose} ? 4 : 1,
                                  repolist => $options{repolist},
                                  recognized_sources =>
                                  [
                                   $options{installsource}
                                  ],
                                  runfile =>
                                  {
                                   location => $options{runfile},
                                   standalone => 1,
                                   relocate_path => "sketches"
                                  },
                                  vardata => "$inputs_root/vardata.conf",
                                 });
    print ">> $config\n";
    print $api "$config\n";

    my $data = $dcapi->cencode({
                                dc_api_version => "0.0.1",
                                request => $request,
                               });
    print ">> $data\n";
    print $api "$data\n";

}
