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

######################################################################
my $VERSION="3.5.0b1";
my $DATE="March 2013";
######################################################################

my $inputs_root;
my $configdir;
my @toremove;

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
use File::Temp qw/tempfile tempdir /;
use Parser;

$| = 1;                                 # autoflush

# for encode/decode, not to use it directly!!!
my $dcapi = DCAPI->new(cfengine_min_version => 1);

use Getopt::Long;

my %options = (
               environment => 'cf_sketch_testing',
               repolist => [ "$inputs_root/sketches" ],
               activate => {},
               install => [],
               uninstall => [],
               force => 0,
               verbose => 0,
               test => 0,
               veryverbose => 0,
               runfile => "$inputs_root/api-runfile.cf",
               installsource => Util::local_cfsketches_source(File::Spec->curdir()) || undef,
               # These are hardcoded above, we put them here for convenience
               version => $VERSION,
               date => $DATE,
              );

Getopt::Long::Configure("bundling");

GetOptions(\%options,
           "expert!",
           "verbose|v!",
           "veryverbose|vv!",
           "generate!",
           "force|f!",
           "test!",
           "installsource|is=s",
           "cfpath=s",
           "list:s",
           "search:s",
           "make_readme:s",
           "install|i=s@",
           "uninstall=s@",
           "deactivate-all|da",
           "activate|a=s%",
           "runfile|rf=s",
           "repolist|rl=s@",
          );

#die "$0: cf-sketch can only be used in --expert mode" unless $options{expert};

die "$0: --installsource DIR must be specified" unless $options{installsource};

$options{verbose} = 1 if $options{veryverbose};

my $sourcedir = dirname($options{installsource});
die "Sorry, can't locate source directory" unless -d $sourcedir;

api_interaction({
                 define_environment => {
                                        $options{environment} =>
                                        {
                                         activated => 1,
                                         test => !!$options{test},
                                         verbose => !!$options{verbose}
                                        }
                                       }
                });

if (exists $options{'make_readme'})
{
    api_interaction({
                     describe => 'README',
                     search => $options{search} eq '' ? '.' : $options{search}
                    },
                    make_list_printer('search', 'README.md'));
}

if (exists $options{'search'})
{
    api_interaction({
                     describe => 1,
                     search => $options{search} eq '' ? '.' : $options{search}
                    },
                    make_list_printer('search'));
}

if (exists $options{'list'})
{
    api_interaction({
                     describe => 1,
                     list => $options{list} eq '' ? 1 : $options{list}
                    },
                    make_list_printer('list'));
}

if ($options{'deactivate-all'})
{
    api_interaction({deactivate => 1});
}

if (scalar @{$options{install}})
{
    my @todo = map
    {
        {
            sketch => $_, force => $options{force}, source => $sourcedir,
             target => $options{repolist}->[0],
         }
    } @{$options{install}};
    api_interaction({install => \@todo});
}

if (scalar @{$options{uninstall}})
{
    my @todo = map
    {
        {
            sketch => $_, target => $options{repolist}->[0],
         }
    } @{$options{uninstall}};
    api_interaction({uninstall => \@todo});
}

if (scalar keys %{$options{activate}})
{
    my %todefine;
    my %todo;
    foreach my $sketch (keys %{$options{activate}})
    {
        my $file = $options{activate}->{$sketch};
        my $load = $dcapi->load($file);
        die "Could not load $file: $!" unless defined $load;

        if (ref $load eq 'ARRAY')
        {
            my $i = 1;
            foreach (@$load)
            {
                my $k = "$file $i";
                $todefine{$k} = $_;
                $i++;
                push @{$todo{$sketch}},{
                                        target => $options{repolist}->[0],
                                        environment => $options{environment},
                                        params => [ $k ],
                                       };
            }
        }
        else
        {
            $todefine{$file} = $load;
            push @{$todo{$sketch}},{
                                    target => $options{repolist}->[0],
                                    environment => $options{environment},
                                    params => [ $file ],
                                   };
        }
    }

    api_interaction({define => \%todefine});

    foreach my $sketch (keys %todo)
    {
        foreach my $activation (@{$todo{$sketch}})
        {
            api_interaction({activate => { $sketch => $activation }});
        }
    }
}

if ($options{'generate'})
{
    api_interaction({regenerate => 1});
}

unless ($options{'expert'}) {
    # Determine where to load command modules from
    (-d ($options{'cmddir'}="$FindBin::Bin/../lib/cf-sketch/Parser/Commands")) ||
    (-d ($options{'cmddir'}="$FindBin::Bin/perl-lib/Parser/Commands")) ||
    ($options{'cmddir'}=undef);

    # Load commands and do other parser initialization
    Parser::init('cf-sketch', \%options, @ARGV);
    Parser::set_welcome_message("[default]\nCFEngine AS, 2012.");

    # Run the main command loop
    Parser::parse_commands();

    # Finishing code.
    Parser::finish();

    exit(0);
}


sub api_interaction
{
    my $request = shift @_;
    my $ok_callback = shift @_;

    my $mydir = dirname($0);
    my $api_bin = "$mydir/cf-dc-api.pl";

    my ($fh_config, $filename_config) = tempfile( "./cf-dc-api-run-XXXX", TMPDIR => 1 );
    my ($fh_data, $filename_data) = tempfile( "./cf-dc-api-run-XXXX", TMPDIR => 1 );

    my $log_level = 1;
    $log_level = 4 if $options{verbose};
    $log_level = 5 if $options{veryverbose};

    my $config = $dcapi->cencode({
                                  log => "STDERR",
                                  log_level => $log_level,
                                  repolist => $options{repolist},
                                  recognized_sources =>
                                  [
                                   $sourcedir
                                  ],
                                  runfile =>
                                  {
                                   location => $options{runfile},
                                   standalone => 1,
                                   relocate_path => "sketches"
                                  },
                                  vardata => "$inputs_root/cfsketch-vardata.conf",
                                 });
    print ">> $config\n" if $options{verbose};
    print $fh_config "$config\n";
    close $fh_config;

    my $data = $dcapi->cencode({
                                dc_api_version => "0.0.1",
                                request => $request,
                               });
    print ">> $data\n" if $options{verbose};
    print $fh_data "$data\n";
    close $fh_data;

    print "Running [$api_bin '$filename_config' '$filename_data']\n"
     if $options{veryverbose};
    open my $api, '-|', "$api_bin '$filename_config' '$filename_data'" or die "Could not open $api_bin: $!";

    my $result;
    while (<$api>)
    {
        print "<< $_" if $options{verbose};
        $result = $dcapi->load($_);
    }
    close $api;
    unlink $filename_config, $filename_data;

    my $ok = Util::hashref_search($result, 'api_ok');
    if ($ok)
    {
        $result = $ok;
        my $success = Util::hashref_search($result, 'success');
        if ($success)
        {
            print "OK: Got successful result: ", $dcapi->encode($result), "\n"
             if $options{verbose};
        }
        else
        {
            print "OK: Got unsuccessful result: ", $dcapi->encode($result), "\n"
             if $options{verbose};
        }

        $ok_callback->($success, $result) if defined $ok_callback;
        return ($success, $result);
    }

    print "NOT OK: Got bad result: ", $dcapi->encode($result), "\n";
    exit 1;
    # return (0, $result);
}

sub make_list_printer
{
    my $type = shift @_;
    my $target_file = shift @_;

    return sub
    {
        my $ok = shift @_;
        my $result = shift @_;
        my $list = Util::hashref_search($result, 'data', $type);
        if (ref $list eq 'HASH')
        {
            foreach my $repo (sort keys %$list)
            {
                foreach my $sketch (values %{$list->{$repo}})
                {
                    if ($target_file && ref $sketch eq 'ARRAY')
                    {
                        my ($dir, $content) = @$sketch;
                        my $file = "$dir/$target_file";
                        open my $f, '>', $file
                         or die "Could not write $file: $!";
                        print $f $content;
                        close $f;
                        print "wrote $file...\n";
                    }
                    else
                    {
                        my $name = Util::hashref_search($sketch, qw/metadata name/);
                        my $desc = Util::hashref_search($sketch, qw/metadata description/);
                        print "$name $desc\n";
                    }
                }
            }
        }
    }
}
