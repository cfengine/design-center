#!/usr/bin/perl -w

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
use lib map { $_,
               "$_/File-Path-2.09",
               "$_/File-Which-1.09/lib",
               "$_/JSON-2.53/lib",
               "$_/Mo-0.31/lib" }
 ("$FindBin::Bin/perl-lib", "$FindBin::Bin/../lib/cf-sketch");

use warnings;
use strict;
use DCAPI;
use Util;
use File::Temp qw/tempfile tempdir /;
use Parser;

$| = 1;                                 # autoflush

# for encode/decode, not to use it directly!!!
my $dcapi = DCAPI->new(cfengine_min_version => 1);

# Find constdata.conf
my $constdata=undef;
foreach ($FindBin::Bin, "$FindBin::Bin/perl-lib", "$FindBin::Bin/../lib/cf-sketch", "/var/cfengine/constdata.conf") {
  if (-f "$_/constdata.conf") {
    $constdata = "$_/constdata.conf";
  }
}

use Getopt::Long;

my %options = (
               environment => 'cf_sketch_testing',
               repolist => [],
               activate => {},
               install => [],
               apitest => [],
               coverage => 0,
               uninstall => [],
               filter => [],
               force => 0,
               quiet => 0,
               verbose => 0,
               test => 0,
               ignore => 1,
               activated => 0,
               veryverbose => 0,
               standalone => 0,
               runfile => "$inputs_root/cf-sketch-runfile.cf",
               vardata => undef,
               standalonerunfile => "$inputs_root/cf-sketch-runfile-standalone.cf",
               installsource => Util::local_cfsketches_source(File::Spec->curdir()) || 'https://raw.github.com/cfengine/design-center/master/sketches/cfsketches.json',
               constdata => $constdata,
               # These are hardcoded above, we put them here for convenience
               version => $VERSION,
               date => $DATE,
               dcapi => $dcapi,
              );

Getopt::Long::Configure("bundling", "require_order");

GetOptions(\%options,
           "expert!",
           "quiet|q!",
           "ignore!",
           "coverage!",
           "verbose|v!",
           "veryverbose|vv!",
           "generate!",
           "force|f!",
           "test:s",
           "activated:s",
           "installsource|is=s",
           "cfpath=s",
           "list:s",
           "search:s",
           "make_readme:s",
           "filter=s@",
           "install|i=s@",
           "apitest=s@",
           "apiconfig=s",
           "uninstall=s@",
           "deactivate-all|da",
           "activate|a=s%",
           "constdata=s",

           "standalone!",
           "runfile|rf=s",
           "vardata=s",
           "standalonerunfile|srf=s",
           "repolist|rl=s@",
          );

#die "$0: cf-sketch can only be used in --expert mode" unless $options{expert};

die "$0: --installsource FILE must be specified" unless $options{installsource};

my $sourcedir = dirname($options{installsource});
$options{sourcedir} = $sourcedir;

if (Util::is_resource_local($options{installsource}))
{
    die "$0: $options{installsource} is not a file" unless (-f "$options{installsource}");
    die "Sorry, can't locate source directory" unless -d $sourcedir;
}
else
{
    my $remote = Util::get_remote($options{installsource});
    die "Could not retrieve remote URL $options{installsource}, aborting"
        unless $remote;

    warn <<EOHIPPUS;

You are using a remote sketch repository ($options{installsource}),
which may be slow.  If you run cf-sketch with the --installsource option
pointing to cfsketches.json, or run it in your Design Center checkout directory,
or give the DC API a config.json with a 'recognized_source' parameter, it will
find your local Design Center checkout more easily and avoid network queries

EOHIPPUS
}

$options{repolist} = [ "$inputs_root/sketches" ] unless scalar @{$options{repolist}};
$options{verbose} = 1 if $options{veryverbose};

$options{test} = 1 if ($options{test} eq '');
my $env_test = $options{test};

$options{activated} = 1 if ($options{activated} eq '');
my $env_activated = $options{activated};

die "Sorry, can't locate constdata file '$options{constdata}'" unless (!$options{constdata} || -f $options{constdata});

api_interaction({
                 define_environment => {
                                        $options{environment} =>
                                        {
                                         activated => 1,
                                         test => $env_test,
                                         activated => $env_activated,
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
                     list => $options{list} eq '' ? '.' : $options{list}
                    },
                    make_list_printer('list'));
}

if ($options{'deactivate-all'})
{
    api_interaction({deactivate => 1});
}

if (scalar @{$options{install}})
{
    my @todo;
    foreach (@{$options{install}})
    {
        push @todo, split ',', $_;
    }

    @todo = map
    {
        {
            sketch => $_, force => $options{force}, source => undef, target => undef
        }
    } @todo;
    api_interaction({install => \@todo}, undef, undef, [qw/source target/]);
}

if (scalar @{$options{apitest}})
{
    my @todo;
    foreach (@{$options{apitest}})
    {
        push @todo, join('|', split ',', $_);
    }

    api_interaction({test => \@todo, coverage => $options{coverage}});
}

if (scalar @{$options{uninstall}})
{
    my @todo = map
    {
        {
            sketch => $_, target => undef,
         }
    } @{$options{uninstall}};
    api_interaction({uninstall => \@todo}, undef, undef, [qw/target/]);
}

if (scalar keys %{$options{activate}})
{
    my %todefine;
    my %todo;
    foreach my $sketch (keys %{$options{activate}})
    {
        my $file = $options{activate}->{$sketch};
        my ($load, @warnings) = $dcapi->load($file);
        die "Could not load $file: @warnings" unless defined $load;

        if (ref $load eq 'ARRAY')
        {
            my $i = 1;
            foreach (@$load)
            {
                my $k = "parameter definition from $file-$i";
                $todefine{$k} = $_;
                $i++;
                push @{$todo{$sketch}},{
                                        environment => $options{environment},
                                        params => [ $k ],
                                        target => undef,
                                       };
            }
        }
        else
        {
            my $k = "parameter definition from $file";
            $todefine{$k} = $load;
            push @{$todo{$sketch}},{
                                    environment => $options{environment},
                                    params => [ $k ],
                                    target => undef,
                                   };
        }
    }

    api_interaction({define => \%todefine});

    foreach my $sketch (keys %todo)
    {
        foreach my $activation (@{$todo{$sketch}})
        {
            api_interaction({activate => { $sketch => $activation }}, undef, undef, [qw/target/]);
        }
    }
}

if ($options{'generate'})
{
    api_interaction({regenerate => 1});
}

unless ($options{'expert'}) {
    use Term::ANSIColor qw(:constants);
    $Term::ANSIColor::AUTORESET = 1;

    # Determine where to load command modules from
    (-d ($options{'cmddir'}="$FindBin::Bin/../lib/cf-sketch/Parser/Commands")) ||
    (-d ($options{'cmddir'}="$FindBin::Bin/perl-lib/Parser/Commands")) ||
    ($options{'cmddir'}=undef);

    # Load commands and do other parser initialization
    Parser::init('cf-sketch', \%options, @ARGV);
    Parser::set_welcome_message("[default]\nCFEngine AS, 2013.");

    # Run the main command loop
    Parser::parse_commands();

    # Finishing code.
    Parser::finish();

    exit(0);
}

sub api_interaction
{
    my $request = shift @_;
    my $callback = shift @_;
    my $mergeopts = shift @_;
    my $request_fill = shift @_;

    my $mydir = dirname($0);
    my $api_bin = "$mydir/cf-dc-api.pl";

    my ($fh_config, $filename_config) = tempfile( "./cf-dc-api-run-XXXX", TMPDIR => 1 );
    my ($fh_data, $filename_data) = tempfile( "./cf-dc-api-run-XXXX", TMPDIR => 1 );

    my $log_level = 0;
    $log_level = 4 if $options{verbose};
    $log_level = 5 if $options{veryverbose};

    my $opts = {
                log => "pretty",
                log_level => $log_level,
                repolist => $options{repolist},
                recognized_sources =>
                [
                 $sourcedir
                ],
                runfile =>
                {
                 location => $options{standalone} ? $options{standalonerunfile} : $options{runfile},
                 standalone => $options{standalone},
                 relocate_path => "sketches",
                 filter_inputs => $options{filter},
                },
                vardata => $options{vardata} || "$inputs_root/cfsketch-vardata.conf",
                constdata => $options{constdata},
               };

    if (exists $options{apiconfig})
    {
        my $error;
        print ">> OVERRIDING CONFIG FROM $options{apiconfig}\n" if $options{verbose};
        ($opts, $error) = $dcapi->load($options{apiconfig});
        die $error if defined $error;
    }

    # Merge passed options, if any
    if ($mergeopts) {
      for my $k (keys %$mergeopts) {
        $opts->{$k} = $mergeopts->{$k};
      }
    }
    my $config = $dcapi->cencode($opts);
    print ">> $config\n" if $options{verbose};
    print $fh_config "$config\n";
    close $fh_config;

    if (defined $request_fill)
    {
        foreach my $fill (@$request_fill)
        {
            my $data;
            if ($fill eq 'source')
            {
                $data = $sourcedir;
            }
            elsif ($fill eq 'target')
            {
                $data = $options{repolist}->[0];
            }
            else
            {
                warn "Unknown request fill $fill!";
                next;
            }

            replace_attribute($request, $fill, $data);
        }
    }

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
            Util::success("OK: Got successful result: ".$dcapi->encode($result)."\n")
             if $options{verbose};
            Util::print_api_messages($result);
        }
        else
        {
            print "OK: Got unsuccessful result: ".$dcapi->encode($result)."\n"
              if $options{verbose};
            Util::print_api_messages($result);
        }

        unless (defined $callback)
        {
            $callback = sub
            {
                my $success = shift @_;
                my $result = shift @_;
                if (!$success && !$options{ignore})
                {
                    exit 1;
                }
            };
        }

        $callback->($success, $result) if defined $callback;

        return ($success, $result);
    }
    elsif (my $errors = Util::hashref_search($result, qw/api_error errors/))
    {
        Util::error("API fatal error: @{[ join ';', @$errors ]}\n");
    }
    else
    {
        Util::error("API fatal error: Got bad result: ".$dcapi->encode($result)."\n");
    }
    exit 1;
    # return (0, $result);
}

sub replace_attribute
{
     my $container = shift @_;
     my $fill = shift @_;
     my $data = shift @_;

     return unless defined $container;

     if (ref $container eq 'HASH')
     {
         if (exists $container->{$fill})
         {
             $container->{$fill} = $data;
             return;
         }

         replace_attribute($_, $fill, $data) foreach values %$container;
     }
     elsif (ref $container eq 'ARRAY')
     {
         replace_attribute($_, $fill, $data) foreach @$container;
     }
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

# Common API actions

# Return details of sketches according to regex. Without args returns all sketches
sub get_all_sketches {
  my $regex = Util::validate_and_set_regex(shift);
  my ($success, $result) = main::api_interaction({
                                                  describe => 1,
                                                  search => $regex,
                                                 });
  my $list = Util::hashref_search($result, 'data', 'search');
  my $res = undef;
  if (ref $list eq 'HASH')
  {
    $res = {};
    foreach my $repo (keys %$list) {
      foreach my $sketch (keys %{$list->{$repo}}) {
        $res->{$sketch} = $list->{$repo}->{$sketch};
      }
    }
  }
  else
  {
    Util::error("Internal error: The API 'search' command returned an unknown data structure.");
  }
  return $res;
}

# Alias for get_all_sketches
sub get_sketch {
  return get_all_sketches(shift);
}

# Return list of installed sketches and their repositories
sub get_installed {
    my ($success, $result) = main::api_interaction({
                                                 describe => 0,
                                                 list => '.',
                                                });
    my $list = Util::hashref_search($result, 'data', 'list');
    my $installed = {};
    if (ref $list eq 'HASH')
    {
        foreach my $repo (keys %$list)
        {
            foreach my $sketch (keys %{$list->{$repo}})
            {
                $installed->{$sketch} = $repo;
            }
        }
    }
    else
    {
        Util::error("Internal error: The API 'list' command returned an unknown data structure.");
    }
    return $installed;
}

# Return whether a sketch is installed
sub is_sketch_installed
{
  my $sketch = shift;
  my $installed = get_installed;
  return exists($installed->{$sketch});
}

# Return all activations
sub get_activations {
    my ($success, $result) = main::api_interaction({ activations => 1 });
    my $activs = Util::hashref_search($result, 'data', 'activations');
    if (ref $activs eq 'HASH')
    {
        return $activs;
    }
    else
    {
        Util::error("Internal error: The API 'activations' command returned an unknown data structure.");
        return undef;
    }
}

# Return all parameter definitions
sub get_definitions {
  my ($success, $result) = main::api_interaction({ definitions => 1 });
  return unless $success;
  my $defs = Util::hashref_search($result, 'data', 'definitions');
  if (ref $defs eq 'HASH') {
    return $defs;
  }
  else {
    Util::error("Internal error: The API 'definitions' command returned an unknown data structure.");
    return undef;
  }
}

# Return all environment definitions
sub get_environments {
  my ($success, $result) = main::api_interaction({ environments => 1 });
  return unless $success;
  my $envs = Util::hashref_search($result, 'data', 'environments');
  $envs = {} unless (ref $envs eq 'HASH');
  return $envs;
}

# Get all validations
sub get_validations {
  my ($success, $result) = main::api_interaction({ validations => 1 });
  return unless $success;
  my $vals = Util::hashref_search($result, 'data', 'validations');
  $vals = {} unless (ref $vals eq 'HASH');
  return $vals;
}
