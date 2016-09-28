package DCAPI;

use strict;
use warnings;

use JSON;
use File::Which;
use File::Basename;
use File::Temp qw/tempfile tempdir /;

use DCAPI::Repo;
use DCAPI::Activation;
use DCAPI::Result;
use DCAPI::Validation;

use constant API_VERSION => '3.6.0';
use constant CODER => JSON->new()->allow_barekey()->relaxed()->utf8()->allow_nonref();
use constant CAN_CODER => JSON->new()->canonical()->utf8()->allow_nonref();
use constant REQUIRED_ENVIRONMENT_KEYS => qw/activated verbose/;
use constant OPTIONAL_ENVIRONMENT_KEYS => qw/qa rudder/;

use Mo qw/build default builder coerce is required/;

our @vardata_keys = qw/compositions activations definitions environments validations expansions/;
our @constdata_keys = qw/selftests/;

has version => ( is => 'ro', default => sub { API_VERSION } );

has config => ( );

has cfagent => (
                is => 'ro',
                default => sub
                {
                    my $c = which('cf-agent');

                    $c = '/var/cfengine/bin/cf-agent' unless $c;

                    return $c if -x $c;

                    return $ENV{CF_AGENT_OVERRIDE};
                }
               );

has cfpromises => (
                   is => 'ro',
                   default => sub
                   {
                       my $c = which('cf-promises');
                       $c = '/var/cfengine/bin/cf-promises' unless $c;

                       return $c if -x $c;

                       return $ENV{CF_PROMISES_OVERRIDE};
                   }
                  );

has repos => ( is => 'ro', default => sub { [] } );
has recognized_sources => ( is => 'ro', default => sub { [] } );
has vardata => ( is => 'rw');
has constdata => ( is => 'rw');
has runfile => ( is => 'ro', default => sub { {} } );
has compositions => ( is => 'rw', default => sub { {} });
has definitions => ( is => 'rw', default => sub { {} });
has activations => ( is => 'rw', default => sub { {} });
has validations => ( is => 'rw', default => sub { {} });
has expansions => ( is => 'rw', default => sub { {} });
has environments => ( is => 'rw', default => sub { { } } );
has selftests => ( is => 'rw', default => sub { [] } );

has cfengine_min_version => ( is => 'ro', required => 1 );
has cfengine_version => ( is => 'rw' );

has forced_cache => ( is => 'ro', default => sub { {} } );

has coder =>
(
 is => 'ro',
 default => sub { CODER },
);

has canonical_coder =>
(
 is => 'ro',
 default => sub { CAN_CODER },
);

sub BUILD
{
    my $self = shift @_;

    if (exists $ENV{CF_VERSION_OVERRIDE})
    {
        $self->cfengine_version($ENV{CF_VERSION_OVERRIDE});
    }
    else
    {
        my $bin = $self->cfagent();
        my $cfv = `$bin -V`;
        if ($cfv =~ m/\s+(\d+\.\d+\.\d+)/)
        {
            $self->cfengine_version($1);
        }
    }
}

sub set_config
{
    my $self = shift @_;
    my $file = shift @_;

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    $self->config($self->load($file));

    my @repos = @{(Util::hashref_search($self->config(), qw/repolist/) || [])};
    return $result->add_error('repolist', "No repolist entries were provided")
     unless scalar @repos;

    $self->log5("Adding recognized repo $_") foreach @repos;
    push @{$self->repos()}, @repos;

    my $runfile = Util::hashref_search($self->config(), qw/runfile/);

    if (ref $runfile ne 'HASH')
    {
        $result->add_error('syntax', "runfile is not a hash");
    }
    else
    {
        %{$self->runfile()} = %$runfile;
        $self->runfile()->{location} = "$repos[0]/meta/api-runfile.cf"
         unless exists $self->runfile()->{location};
    }

    my @sources = @{(Util::hashref_search($self->config(), qw/recognized_sources/) || [])};
    $self->log5("Adding recognized source $_") foreach @sources;
    push @{$self->recognized_sources()}, @sources;

    foreach my $location (@{$self->repos()}, @{$self->recognized_sources()})
    {
        next unless Util::is_resource_local($location);

        eval
        {
            $self->load_repo($location);
        };

        if ($@)
        {
            $result->add_error($location, $@);
        }
    }

    my $vardata_file = Util::hashref_search($self->config(), qw/vardata/) || "$repos[0]/meta/vardata.conf";# TODO: verify!

    $vardata_file = glob($vardata_file);
    $self->log5("Loading vardata file $vardata_file");

    $self->vardata($vardata_file);

    my ($v_data, @v_warnings);
    if ($vardata_file eq '-')
    {
        $self->log("Ignoring vardata file '$vardata_file' as requested");
        $v_data = {};
        $v_data->{$_} = $self->$_() foreach @vardata_keys;
    }
    else
    {
        if (!(-f $vardata_file && -w $vardata_file && -r $vardata_file))
        {
            $self->log("Creating missing vardata file $vardata_file");
            my ($ok, @save_warnings) = $self->save_vardata();

            $result->add_error('vardata', @save_warnings)
             unless $ok;
        }

        ($v_data, @v_warnings) = $self->load($vardata_file);
        $result->add_error('vardata', @v_warnings)
         if scalar @v_warnings;
    }

    if (ref $v_data ne 'HASH')
    {
        $result->add_error($vardata_file, "vardata is not a hash");
    }
    else
    {
        $self->log3("Successfully loaded vardata file $vardata_file");

        unless (exists $v_data->{expansions})
        {
            $v_data->{expansions} = {};
        }

        foreach my $key (@vardata_keys)
        {
            if (exists $v_data->{$key})
            {
                $self->$key(Util::hashref_merge($self->$key(), $v_data->{$key}));
            }
            else
            {
                $result->add_error($vardata_file, "vardata has no key '$key'");
            }
        }
    }

    my $constdata_file = Util::hashref_search($self->config(), qw/constdata/) || "$repos[0]/meta/constdata.conf";# TODO: verify!

    $constdata_file = glob($constdata_file);
    $self->log5("Loading constdata file $constdata_file");
    $self->constdata($constdata_file);

    if ($constdata_file eq '-')
    {
        $self->log("Ignoring constdata file '$constdata_file' as requested");
        $v_data = {};
        @v_warnings = ();
    }
    else
    {
        if (-f $constdata_file && -r $constdata_file)
        {
            ($v_data, @v_warnings) = $self->load($constdata_file);
            $result->add_error('constdata', @v_warnings)
             if scalar @v_warnings;
        }
    }

    foreach my $key (@vardata_keys)
    {
        if (ref $v_data eq 'HASH' && exists $v_data->{$key} && ref $v_data->{$key} eq 'HASH' && ref $self->$key() eq 'HASH')
        {
            foreach my $subkey (sort keys %{$v_data->{$key}})
            {
                $self->log5("Successfully loaded override $key/$subkey from constdata file $constdata_file");
                $self->$key()->{$subkey} = $v_data->{$key}->{$subkey};
            }
        }
    }

    foreach my $key (@constdata_keys)
    {
        if (exists $v_data->{$key})
        {
            $self->log5("Successfully loaded constdata $key from constdata file $constdata_file");
            $self->$key($v_data->{$key});
        }
    }

    return $result;
}

sub save_vardata
{
    my $self = shift;

    my $data = {};
    $data->{$_} = $self->$_() foreach @vardata_keys;
    my $vardata_file = $self->vardata();

    if ($vardata_file eq '-')
    {
        $self->log("Not saving vardata file '$vardata_file' as requested");
        return 1;
    }

    $self->log("Saving vardata file $vardata_file");

    my $dest_dir = File::Basename::dirname($vardata_file);
    unless (-d $dest_dir)
    {
        $self->log("Attempting to create the missing vardata directory $dest_dir");

        Util::dc_make_path($dest_dir);
    }

    open my $fh, '>', $vardata_file
     or return (0, "Vardata file $vardata_file could not be created: $!");

    print $fh $self->cencode_pretty($data);
    close $fh;

    return 1;
}

sub save_runfile
{
    my $self = shift @_;
    my $data = shift @_;
    my $result = shift @_;

    my $runfile = glob($self->runfile()->{location});

    $result->add_data_key("runfile", "runfile", $runfile);

    $self->log("Saving runfile $runfile");
    open my $fh, '>', $runfile
     or return $result->add_warning('save runfile',
                                    "Run file $runfile could not be created: $!");

    print $fh $data;
    close $fh;

    return $result;
}

sub semantic_sprintf
{
    my $todo = shift @_;
    $todo =~ s/^(\d+\.)?(\d+\.)?(\d+)$/sprintf("%010d.%010d.%010d", $1, $2, $3)/e;
    return $todo;
}

sub is_ok_cfengine_version
{
    my $self = shift @_;
    my $req = shift @_ || $self->cfengine_min_version();

    return 0 unless defined $req;

    return semantic_sprintf($req) le semantic_sprintf($self->cfengine_version());
}

sub all_repos
{
    my $self = shift;
    my $sources_first = shift;

    if ($sources_first)
    {
        return ( @{$self->recognized_sources()}, @{$self->repos()} );
    }

    return ( @{$self->repos()}, @{$self->recognized_sources()} );
}

# note it's not "our" but "my"
my %repos;
sub load_repo
{
    my $self = shift;
    my $repo = shift;

    unless (exists $repos{$repo})
    {
        $repos{$repo} = DCAPI::Repo->new(api => $self,
                                         location => glob($repo));
    }

    return $repos{$repo};
}

sub data_dump
{
    my $self = shift;
    return
    {
     version => $self->version(),
     config => $self->config(),
     repolist => $self->repos(),
     recognized_sources => $self->recognized_sources(),
     vardata => $self->vardata(),
     runfile => $self->runfile(),
     map { $_ => $self->$_() } @vardata_keys,
     map { $_ => $self->$_() } @constdata_keys,
    };
}

sub search
{
    my $self = shift;
    my $term_data = shift;
    my $options = shift || {};

    my $results = $self->collect_int($self->recognized_sources(), $term_data, $options);
    my $count = 0;
    foreach (keys %$results)
    {
        $count += scalar keys %{$results->{$_}};
    }

    my %ret;

    $ret{count} = $count;

    unless ($options->{count_only})
    {
        $ret{search} = $results;
    }

    return DCAPI::Result->new(api => $self,
                              status => 1,
                              success => 1,
                              data => \%ret);
}

sub list
{
    my $self = shift;
    my $term_data = shift;
    my $options = shift || {};

    my $results = $self->collect_int($self->repos(), $term_data, $options);
    my $count = 0;
    foreach (keys %$results)
    {
        $count += scalar keys %{$results->{$_}};
    }

    my %ret;

    $ret{count} = $count;

    unless ($options->{count_only})
    {
        $ret{list} = $results;
    }

    return DCAPI::Result->new(api => $self,
                              status => 1,
                              success => 1,
                              data => \%ret);
}

sub selftests
{
    my $self = shift;
    return DCAPI::Result->new(api => $self,
                              status => 1,
                              success => 1,
                              data => { selftests => $self->selftests() });
}

# Note this facility is intentionally not very careful about data
# inputs and reference types.  It's for internal DC use only, not for
# general access like the test() function which tests a sketch.

sub selftest
{
    my $self = shift;
    my $regex = shift;

    my @log;
    my @results;

    my $success = 1;
    $self->log("Running self-tests %s", $self->selftests());

    foreach my $test (@{$self->selftests()})
    {
        $self->config()->{log} = \@log;
        next unless ($regex eq 'any' || $test->{name} =~ m/$regex/);
        $self->log("Running self-test %s", $test);

        foreach my $subtest (@{$test->{subtests}})
        {
            my @sublog;
            $self->config()->{log} = \@sublog;
            my $expect = $subtest->{expected};
            my $expect_match = $subtest->{expected_match};
            my $command = $subtest->{command};
            $self->log3("Testing: command %s, expected %s", $command, $expect);
            my $result = $self->dispatch({
                                          dc_api_version => $self->version(),
                                          request => $command
                                         }, \@sublog);

            my $ok = 1;
            if (ref $result eq 'DCAPI::Result')
            {
                $result = $result->data_dump();

                foreach my $k (sort keys %$expect)
                {
                    my $v = Util::hashref_search($result, 'api_ok', $k);
                    $self->log4("Result '%s': '%s', expected '%s'",
                                $k, $v, $expect->{$k});

                    if ($self->cencode($v) ne $self->cencode($expect->{$k}))
                    {
                        $ok = 0;
                    }
                }

                if (defined $expect_match)
                {
                    if ($self->cencode($result) !~ m/$expect_match/)
                    {
                        $ok = 0;
                    }
                }
            }

            $success &&= $ok;
            push @results, { test => $test->{name},
                             subtest => $subtest,
                             result => $result,
                             log => \@sublog,
                             subtest_success => Util::json_boolean($ok) };
        }
    }

    my @passed = grep { $_->{subtest_success} } @results;

    DCAPI::Result->new(api => $self,
                       status => 1,
                       success => Util::json_boolean($success),
                       data =>
                       {
                           log => \@log,
                           results => \@results,
                           tests_total => scalar @results,
                           tests_passed => scalar @passed,
                           tests_passed_pct => scalar @results ? (scalar @passed * 100.0) / scalar @results : 100,
                       });
}

sub test
{
    my $self = shift;

    my $tests = $self->collect_int($self->repos(), @_);

    my $total = 0;
    my $coverage = 0;
    my $good = 1;
    foreach my $repo (keys %$tests)
    {
        foreach my $sketch (keys %{$tests->{$repo}})
        {
            $total++;
            my $test = $tests->{$repo}->{$sketch};
            if (ref $test eq 'HASH')
            {
                $good = 0 unless $test->{success};
                $coverage += !! scalar keys %{$test->{total}};
            }
            else                        # coverage mode
            {
                $coverage += !! $test;
            }
        }
    }

    return DCAPI::Result->new(api => $self,
                              status => 1,
                              success => $good,
                              data => { test => $tests, total => $total, coverage => $coverage });
}

sub collect_int
{
    my $self = shift;
    my $repos = shift;
    my $term_data = shift;
    my $options = shift || {};

    my @full_list;
    my %ret;
    foreach my $location (@$repos)
    {
        $self->log("Searching location %s for terms %s",
                   $location,
                   $term_data);
        my $repo = $self->load_repo($location);
        my %list = map
        {
            if ($options->{describe} && $options->{describe} eq 'README')
            {
                $_->name() => [ $_->location(), $_->make_readme()];
            }
            elsif ($options->{describe})
            {
                $_->name() => $_->data_dump();
            }
            elsif ($options->{test})
            {
                $_->name() => $_->test($options);
            }
            else
            {
                $_->name() => $_->name();
            }
        }
        $repo->list($term_data);

        $ret{$repo->location()} = \%list;
        push @full_list, values %list;
    }

    return exists $options->{flatten} ? \@full_list : \%ret;
}

sub describe
{
    my $self = shift;

    return DCAPI::Result->new(api => $self,
                              status => 1,
                              success => 1,
                              data => { describe => $self->describe_int(@_) });
}

sub describe_int
{
    my $self = shift;
    my $sketches_top = shift;
    my $sources = shift;
    my $firstfound = shift;

    $sketches_top = { $sketches_top => undef } unless ref $sketches_top eq 'HASH';

    my %ret;
    my @repos = defined $sources ? (@$sources) : ($self->all_repos());
    foreach my $location (@repos)
    {
        my %sketches = %$sketches_top;
        my $repo = $self->load_repo($location);
        my $found = $repo->describe(\%sketches, $firstfound);
        $ret{$repo->location()} = $found;
        return $found if ($found && $firstfound);
    }

    return \%ret;
}

sub install
{
    my $self    = shift;
    my $install = shift;

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    # we don't accept strings, the sketches to be installed must be in an array

    if (ref $install eq 'HASH')
    {
        $install = [ $install ];
    }

    if (ref $install ne 'ARRAY')
    {
        return $result->add_error('syntax',
                                  "Invalid install command");
    }

    my @install_log;

 INSTALLER:
    foreach my $installer (@$install)
    {
        my %d;
        foreach my $varname (qw/sketch source target/)
        {
            my $v = Util::hashref_search($installer, $varname);

            unless (defined $v)
            {
                eval
                {
                    if ($varname eq 'source')
                    {
                        $self->log3("No source specified, trying each one from recognized_sources %s", $self->recognized_sources());
                        $v = $self->recognized_sources();
                    }
                    elsif ($varname eq 'target')
                    {
                        $self->log3("No target specified, trying the first one from repolist");
                        $v = $self->repos()->[0];
                    }
                };
            }

            unless (defined $v)
            {
                $result->add_error('syntax',
                                   "Installer command was missing key '$varname'");
                next INSTALLER;
            }
            $d{$varname} = $v;
        }

        # copy optional install criteria
        foreach my $varname (qw/version force/)
        {
            my $v = Util::hashref_search($installer, $varname);
            next unless defined $v;
            $d{$varname} = $v;
        }

        if (ref $d{source} ne 'ARRAY')
        {
            $d{source} = [$d{source}];
        }

        my $location = $d{target};

        my $drepo;

        eval
        {
            $drepo = $self->load_repo($d{target});
        };

        if ($@)
        {
            $result->add_error('install target', $@);
        }

        next INSTALLER unless defined $drepo;

        if ($drepo->find_sketch($d{sketch}))
        {
            $self->log3("Sketch $d{sketch} is already in target repo");
            $self->log5("forced cache = %s", $self->forced_cache());
            if ($d{force} && !exists $self->forced_cache()->{$d{target}}->{$d{sketch}})
            {
                $self->log("With force=true, overwriting sketch $d{sketch} in $d{target};");
                $self->forced_cache()->{$d{target}}->{$d{sketch}}++;
            }
            elsif (exists $self->forced_cache()->{$d{target}}->{$d{sketch}})
            {
                $self->log3("Sketch $d{sketch} has already been force-installed");
                next INSTALLER;
            }
            else
            {
                $result->add_log("already have $d{sketch}",
                                 "Sketch $d{sketch} is already in target repo; you must uninstall it first");
                next INSTALLER;
            }
        }

        my $sketch;
    SOURCE_CANDIDATE:
        foreach my $source_candidate (@{$d{source}})
        {
            my $srepo;

            eval
            {
                $srepo = $self->load_repo($source_candidate);
            };

            if ($@)
            {
                $result->add_error('install source', $@);
            }

            next SOURCE_CANDIDATE unless defined $srepo;

            $sketch = $srepo->find_sketch($d{sketch}, $d{version});

            unless (defined $sketch)
            {
                next SOURCE_CANDIDATE;
            }

            my $depcheck = $sketch->resolve_dependencies(install => 1,
                                                         force => $d{force},
                                                         source => $d{source},
                                                         target => $d{target});

            return $depcheck unless $depcheck->success();

            $self->log("Installing sketch: %s", \%d);

            my $install_check = $drepo->install($srepo, $sketch);
            $result->merge($install_check);
            $result->add_data_key($d{sketch},
                                  ['install', $d{target}, $d{sketch}],
                                  1);
        }

        unless (defined $sketch)
        {
            $result->add_error($d{sketch},
                               "Sketch $d{sketch} could not be found in source repo");
            next INSTALLER;
        }

    }

    return $result;
}

sub uninstall
{
    my $self = shift;
    my $uninstall = shift;

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    # we don't accept strings, the sketches to be installed must be in an array

    if (ref $uninstall eq 'HASH')
    {
        $uninstall = [ $uninstall ];
    }

    if (ref $uninstall ne 'ARRAY')
    {
        return $result->add_error('syntax',
                                  "Invalid uninstall command");
    }

    my @uninstall_log;

  UNINSTALLER:
    foreach my $uninstaller (@$uninstall)
    {
        my %d;
        foreach my $varname (qw/sketch target/)
        {
            my $v = Util::hashref_search($uninstaller, $varname);
            unless (defined $v)
            {
                $result->add_error('syntax',
                                   "Uninstaller command was missing key '$varname'");
                next UNINSTALLER;
            }
            $d{$varname} = $v;
        }

        # copy optional install criteria
        foreach my $varname (qw/version/)
        {
            my $v = Util::hashref_search($uninstaller, $varname);
            next unless defined $v;
            $d{$varname} = $v;
        }

        my $repo;

        eval
        {
            $repo = $self->load_repo($d{target});
        };

        if ($@)
        {
            $result->add_error('uninstall target',
                               $@);
        }

        next UNINSTALLER unless defined $repo;

        my $sketch = $repo->find_sketch($d{sketch});

        unless ($sketch)
        {
            $result->add_error('uninstall target',
                               "Sketch $d{sketch} is not in target repo; you must install it first");
            next UNINSTALLER;
        }

        $self->log("Uninstalling sketch $d{sketch} from " . $sketch->location());

        $result->merge($repo->uninstall($sketch));

        $result->add_data_key($d{sketch},
                              ['uninstall', $d{target}, $d{sketch}],
                              1);
    }

    return $result;
}

sub define
{
    my $self = shift;
    my $define = shift;

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    if (ref $define ne 'HASH')
    {
        return $result->add_error('syntax',
                                  "Invalid define command");
    }

    foreach my $dkey (keys %$define)
    {
        if (ref $define->{$dkey} ne 'HASH')
        {
            return $result->add_error('syntax',
                                      "Invalid define command: key $dkey");
        }

        foreach my $pkey (sort keys %{$define->{$dkey}})
        {
            next if ref $define->{$dkey}->{$pkey} eq 'HASH';
            return $result->add_error('syntax',
                                      "Invalid define command: key $dkey/$pkey");
        }

        $self->definitions()->{$dkey} = $define->{$dkey};
        $result->add_data_key($dkey, ['define', $dkey], 1);
    }

    $self->save_vardata();

    return $result;
}

sub undefine
{
    my $self = shift;
    my $undefine = shift;

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    if (ref $undefine ne 'ARRAY')
    {
        return $result->add_error('syntax',
                                  "Invalid undefine command");
    }

    foreach my $ukey (@$undefine)
    {
        $result->add_data_key($ukey,
                              ['undefine', $ukey],
                              !! delete $self->definitions()->{$ukey});
    }

    $self->save_vardata();

    return $result;
}

sub define_environment
{
    my $self = shift;
    my $define_environment = shift;
    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    if (ref $define_environment ne 'HASH')
    {
        return $result->add_error('syntax',
                                  "Invalid define_environment command");
    }

    return $result unless $result->success();

    foreach my $dkey (keys %$define_environment)
    {
        return $result->add_error('environment name',
                                  "Invalid environment name $dkey (must be a valid bundle name)")
         if $dkey =~ m/\W/;

        my $spec = $define_environment->{$dkey};

        if (ref $spec ne 'HASH')
        {
            return $result->add_error('environment spec',
                                      "Invalid environment spec under $dkey");
        }

        foreach my $required (REQUIRED_ENVIRONMENT_KEYS)
        {
            return $result->add_error('environment spec required key',
                                      "Invalid environment spec $dkey: missing key $required")
             unless exists $spec->{$required};

            $spec->{$required} = ! ! $spec->{$required}
             if Util::is_json_boolean($spec->{$required});

            my $ref = ref $spec->{$required};
            if (!$ref)
            {
                # we're OK: it's a scalar
            }
            elsif ($ref eq 'HASH')
            {
                my @condition;
                if (exists $spec->{$required}->{include})
                {
                    return $result->add_error('environment spec has invalid include expression',
                                      "Invalid environment spec $dkey: key $required specified invalid include")
                     unless ref $spec->{$required}->{include} eq 'ARRAY';
                    push @condition, @{$spec->{$required}->{include}};
                }

                # Ignore excludes for now.
                # if (exists $spec->{$required}->{exclude})
                # {
                #     return $result->add_error('environment spec has invalid exclude expression',
                #                       "Invalid environment spec $dkey: key $required specified invalid exclude")
                #      unless ref $spec->{$required}->{exclude} eq 'ARRAY';
                #     push @condition, map { "!$_" } @{$spec->{$required}->{exclude}};
                # }

                return $result->add_error('environment spec has no selectors',
                                          "Invalid environment spec $dkey: key $required is a hash but had nothing to say")
                 unless scalar @condition;
            }
            else
            {
                # only scalars and hash refs are acceptable
                return $result->add_error('environment spec value',
                                          "Invalid environment spec $dkey: non-scalar and non-hashref key '$required'");
            }
        }

        foreach my $optional (OPTIONAL_ENVIRONMENT_KEYS)
        {
            $spec->{$optional} = ! ! $spec->{$optional}
             if Util::is_json_boolean($spec->{$optional});

            my $ref = ref $spec->{$optional};
            if (!$ref)
            {
                # we're OK: it's a scalar
            }
            else
            {
                # only scalars and hash refs are acceptable
                return $result->add_error('environment spec value',
                                          "Invalid environment spec $dkey: non-scalar optional key '$optional'");
            }
        }

        $self->environments()->{$dkey} = $spec;
        $result->add_data_key($dkey, ['define_environment', $dkey], 1);
    }

    $self->save_vardata();
    return $result;
}

sub undefine_environment
{
    my $self = shift;
    my $undefine_environment = shift;

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    if (Util::is_json_boolean($undefine_environment) &&
        $undefine_environment)
    {
        $undefine_environment = [sort keys %{$self->environments()}];
    }

    if (ref $undefine_environment ne 'ARRAY')
    {
        return $result->add_error('syntax',
                                  "Invalid undefine_environment command");
    }

    foreach my $ukey (@$undefine_environment)
    {
        $result->add_data_key($ukey,
                              ['undefine_environment', $ukey],
                              !! delete $self->environments()->{$ukey});
    }

    $self->save_vardata();

    return $result;
}

sub compose
{
    my $self = shift;
    my $compose = shift || [];

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    if (ref $compose ne 'HASH')
    {
        return $result->add_error('syntax',
                                  "Invalid compose command");
    }

    $self->compositions()->{$_} = $compose->{$_} foreach keys %$compose;
    $result->add_data_key('compose', 'compositions', $self->compositions());

    $self->save_vardata();

    return $result;
}

sub decompose
{
    my $self = shift;
    my $compose_key = shift || [];

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    # delete and return in one statement
    $result->add_data_key('compose', 'compositions',
                          delete $self->compositions()->{$compose_key});

    $self->save_vardata();

    return $result;
}

sub define_validation
{
    my $self = shift;
    my $define_validation = shift || [];

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    if (ref $define_validation ne 'HASH')
    {
        return $result->add_error('syntax',
                                  "Invalid define_validation command");
    }

    foreach my $vdef (keys %$define_validation)
    {
        my $result = DCAPI::Validation::make_validation($self, $vdef, $define_validation->{$vdef});
        if (ref $result ne 'DCAPI::Result')
        {
            $self->validations()->{$vdef} = $define_validation->{$vdef};
        }
        else
        {
            return $result;
        }
    }

    $result->add_data_key('define_validation', 'validations', $self->validations());

    $self->save_vardata();

    return $result;
}

sub undefine_validation
{
    my $self = shift;
    my $undefine_validation_key = shift || [];

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    # delete and return in one statement
    $result->add_data_key('undefine_validation', 'validations',
                          delete $self->validations()->{$undefine_validation_key});

    $self->save_vardata();

    return $result;
}

sub validate
{
    my $self = shift;
    my $validate = shift || [];

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    if (ref $validate ne 'HASH')
    {
        return $result->add_error('syntax',
                                  "Invalid validate command");
    }

    unless (exists $validate->{validation})
    {
        return $result->add_error('syntax',
                                  "Invalid validate command: no validation key");
    }

    unless (exists $self->validations()->{$validate->{validation}})
    {
        return $result->add_error('syntax',
                                  "Invalid validate command: unknown validation key");
    }

    unless (exists $validate->{data})
    {
        return $result->add_error('syntax',
                                  "Invalid validate command: no data key");
    }

    my $validation = DCAPI::Validation::make_validation($self,
                                                        $validate->{validation},
                                                        $self->validations()->{$validate->{validation}});

    if (ref $validation eq 'DCAPI::Validation') # it's a validation
    {
        return $validation->validate($validate->{data});
    }
    elsif (ref $validation eq 'DCAPI::Result') #it's a result object
    {
        return $validation;
    }

    # else, there was an error
    return $result;
}

sub activate
{
    my $self = shift;
    my $activate = shift;

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    if (ref $activate ne 'HASH')
    {
        return $result->add_error('syntax',
                                  "Invalid activate command");
    }

    # handle activation request in form
    # sketch: { environment:"run environment", target:"/my/repo", params: [definition1, definition2, ... ] }
    foreach my $sketch (keys %$activate)
    {
        my $spec = $activate->{$sketch};

        my ($verify, @warnings) = DCAPI::Activation::make_activation($self, $sketch, $spec);

        if ($verify)
        {
            if (ref $spec eq 'HASH')
            {
                $spec->{hash} = $verify->hash();
            }

            $self->log("Activating sketch %s with spec %s", $sketch, $spec);
            my $cspec = $self->cencode($spec);
            if (exists $self->activations()->{$sketch})
            {
                foreach (@{$self->activations()->{$sketch}})
                {
                    if ($cspec eq $self->cencode($_))
                    {
                        return $result->add_log('activation',
                                                "Activation is already in place");
                    }
                }
            }

            push @{$self->activations()->{$sketch}}, $spec;
            $self->log("Activations for sketch %s are now %s",
                       $sketch,
                       $self->activations()->{$sketch});

            $result->add_data_key($sketch,
                                  ['activate', $sketch],
                                  $spec);
        }
        else
        {
            $self->log("FAILED activation of sketch %s with spec %s: %s",
                       $sketch,
                       $spec,
                       @warnings);
            return $result->add_error('activation verification', @warnings);
        }
    }

    $self->save_vardata();

    return $result;
}

sub regenerate
{
    my $self = shift;
    my $regenerate = shift;

    my $expdata = $self->expansions();
    %$expdata = ();

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    my @activations;                 # these are DCAPI::Activation objects
    my $acts = $self->activations(); # these are data structures
    foreach my $sketch (keys %$acts)
    {
        foreach my $spec (@{$acts->{$sketch}})
        {
            # this is how the data structure is turned into a DCAPI::Activation object
            my ($activation, @errors) = DCAPI::Activation::make_activation($self, $sketch, $spec);

            if ($activation)
            {
                my $sketch_obj = $activation->sketch();
                $self->log("Regenerate: adding activation of %s; spec %s", $sketch, $spec);
                push @activations, $activation;
            }
            else
            {
                $self->log("Regenerate: verification errors [@errors]");
                $result->add_error($sketch, @errors);
            }
        }
    }

    return $result unless $result->success();

    @activations = sort { $a->priority() cmp $b->priority() } @activations;

    # resolve each activation from the others
    foreach my $a (@activations)
    {
        my ($resolved, @warnings) = $a->resolve_now(\@activations);

        return $result->add_error($a->sketch()->name(), @warnings)
         unless $resolved;
    }

    # 1. determine includes from sketches, their dependencies, and namespaces
    my @inputs;
    foreach my $a (@activations)
    {
        next unless $a->sketch()->language() eq 'cfengine';
        push @inputs, $a->sketch()->get_inputs($self->runfile()->{relocate_path}, 10);
        $self->log("Regenerate: adding inputs %s", \@inputs);
    }

    @inputs = Util::uniq(@inputs);

    my $filter_inputs = $self->runfile()->{filter_inputs};
    if (ref $filter_inputs eq 'ARRAY')
    {
        foreach my $filter (@$filter_inputs)
        {
            $self->log("Regenerate: filtering inputs to exclude %s", $filter);
            @inputs = grep { $_ !~ m/$filter/ } @inputs;
        }

        $self->log("Regenerate: final inputs after filtering %s", \@inputs);
    }

    my $inputs = join "\n", Util::make_var_lines(0, \@inputs, '', 0, 0);

    my $type_indent = ' ' x 2;
    my $context_indent = ' ' x 4;
    my $indent = ' ' x 6;

    # 2. make cfsketch_g and environment bundles with data
    my @data;
    my $position = 1;

    foreach my $a (@activations)
    {
        $self->log("Regenerate: generating activation %s", $a->id());

        foreach my $p (@{$a->params()})
        {
            if (DCAPI::Activation::container_type($p->{type}))
            {
                my $line = join("\n",
                                sprintf("%s# %s '%s' from definition %s, activation %s",
                                        $indent,
                                        $p->{type},
                                        $p->{name},
                                        $p->{set},
                                        $a->id()),
                                $indent . Util::make_container_line($a->id(), $p->{name}, $self->cencode($p->{value})));
                push @data, $line;
            }
        }
    }

    my %stringified = (
                       activated => 1,
                       test => 1,
                       verbose => 1,
                       qa => 1,
                      );

    my @environment_data;
    my @environment_classes;
    foreach my $e (keys %{$self->environments()})
    {
        # make a copy of the run environment
        my %edata = %{$self->environments()->{$e}};

        # ensure there's an "activated" class
        unless (exists $edata{activated})
        {
            $edata{activated} = "any";
        }

        # stringify every context as needed
        foreach my $k (keys %stringified)
        {
            my $include = Util::hashref_search(\%edata, $k, qw/include/);

            $include = $edata{$k} if (exists $edata{$k} && ref $edata{$k} eq '');

            next unless defined $include;

            # TODO: we're ignoring 'exclude' here
            my $class_name = "${e}_${k}";
            $edata{$k} = $class_name;
            push @environment_classes, map { "$indent$_" } Util::recurse_context_lines($include, $class_name);
        }

        push @environment_data, $indent . Util::make_container_line("", $e, $self->cencode(\%edata));
        $expdata->{$e} = \%edata;
    }

    my $environment_classes = join "\n", @environment_classes;
    my $environment_data = join "\n", @environment_data;

    # 3a. make cfsketch_run bundle with CFEngine bundle invocations
    my @invocation_lines;
    foreach my $a (@activations)
    {
        next unless $a->sketch()->language() eq 'cfengine';
        $self->log3("Regenerate: generating invocation call %s", $a->id());
        $result->add_data_key("activations",
                              $a->id(),
                              [
                               $a->prefix(),
                               $a->sketch()->name(),
                               $a->bundle(),
                               $a->hash()
                              ]);

        my $env_activated_context = $a->environment() . "_activated";

        push @invocation_lines,
         sprintf('%s%s::',
                 $context_indent,
                 $env_activated_context);

        my $namespace = $a->sketch()->namespace();
        my $namespace_prefix = $namespace eq 'default' ? '' : "$namespace:";

        push @invocation_lines, sprintf('%s"%s" -> { "%s", "%s", "%s", "%s" }%susebundle => %s%s(%s),%sinherit => "true", handle => "dc_method_call_%s",%sifvarclass => "%s",%suseresult => "return_%s";',
                                        $indent,
                                        $a->id(),
                                        $a->prefix(),
                                        $a->sketch()->name(),
                                        $a->bundle(),
                                        $a->hash(),
                                        "\n$indent",
                                        $namespace_prefix,
                                        $a->bundle(),
                                        $a->make_bundle_params("\n$indent    ", $a),
                                        "\n$indent",
                                        $a->id(),
                                        "\n$indent",
                                        $a->sketch()->runtime_context(),
                                        "\n$indent",
                                        $a->id());
        push @invocation_lines, "\n";
    }

    # 3b. add external bundle invocations
    my @external_invocation_lines;
    my $modified_vardata = 0;

    foreach my $a (@activations)
    {
        next unless $a->sketch()->language() eq 'perl';
        $self->log3("Regenerate: generating Perl invocation call %s", $a->id());
        $result->add_data_key("perl_activations",
                              $a->id(),
                              [
                               $a->prefix(),
                               $a->sketch()->name(),
                               $a->bundle(),
                               $a->hash()
                              ]);

        my $env_activated_context = $a->environment() . "_activated";

        push @invocation_lines,
         sprintf('%s%s::',
                 $context_indent,
                 $env_activated_context);

        my @external_inputs = $a->sketch()->get_inputs(undef, 10);

        push @external_invocation_lines, sprintf('%s"%s %s %s %s expansions %s" -> { "%s", "%s", "%s", "%s" }%smodule => "true", contain => in_shell, handle => "dc_perl_call_%s",%sifvarclass => "%s";',
                                                 $indent,
                                                 'perl',
                                                 $external_inputs[0],
                                                 $a->bundle(),
                                                 $self->vardata(),
                                                 $a->id(),
                                                 $a->id(),
                                                 $a->sketch()->name(),
                                                 $a->bundle(),
                                                 $a->hash(),
                                                 "\n$indent",
                                                 $a->id(),
                                                 "\n$indent",
                                                 $a->sketch()->runtime_context());
        push @external_invocation_lines, "\n";

        $expdata->{$a->id()} = $a->make_bundle_params("", $a);
        $modified_vardata++;
    }

    $self->save_vardata() if $modified_vardata;

    # 4. print return value reports
    my @report_lines;
    foreach my $a (@activations)
    {
        foreach my $p (grep { DCAPI::Activation::return_type($_->{type}) } @{$a->params()})
        {
            if ($a->sketch()->language() eq 'perl')
            {
                my $context = 'dcreturn';
                my $varname = sprintf("%s_%s", $a->id(), $p->{name});
                #my $context = "return_" . $a->id(); # requires Redmine#6063 to work
                #my $varname = $p->{name}; # requires Redmine#6063 to work
                push @report_lines,
                 sprintf('%s"Perl activation %s returned %s = $(%s_%s_str)";',
                         $indent,
                         $a->id(),
                         $p->{name},
                         $a->id(),
                         $p->{name},
                         );

                my $line = join("\n",
                                sprintf("%s# printable version of return value '%s' for activation %s",
                                        $indent,
                                        $p->{name},
                                        $a->id()),
                                sprintf('%s"%s_%s_str" string => format("%%S", "%s.%s");',
                                        $indent,
                                        $a->id(),
                                        $p->{name},
                                        $context,
                                        $varname),
                               );
                push @data, $line;
            }
            else
            {
                push @report_lines,
                 sprintf('%s"activation %s returned %s = %s";',
                         $indent,
                         $a->id(),
                         $p->{name},
                         sprintf('$(return_%s[%s])', $a->id(), $p->{name}));
            }
        }

        push @report_lines,
         sprintf('%s"activation %s could not run because it requires classes %s" handle => "dc_return_report_%s", ifvarclass => "inform_mode.!(%s)";',
                 $indent,
                 $a->id(),
                 $a->sketch()->runtime_context(),
                 $a->id(),
                 $a->sketch()->runtime_context());
    }

    my $report_lines = join "\n",
     "${context_indent}inform_mode::",
      @report_lines;

    my $data_lines = join "\n\n", @data;

    my $invocation_lines = join "\n", @invocation_lines;
    my $external_invocation_lines = join "\n", @external_invocation_lines;

    my $runfile_header = defined $self->runfile()->{header} ? $self->runfile()->{header} : '# Design Center runfile';

    my $runfile_data = <<EOHIPPUS;
$runfile_header

body file control
{
      inputs => $inputs;
}

bundle common cfsketch_g
{
  vars:
      # legacy list, please ignore
      "inputs" slist => { "cf_null" };
}

bundle agent cfsketch_run
{
  classes:
$environment_classes
  vars:
$environment_data
$data_lines

  methods:
    any::
      "cfsketch_g" usebundle => "cfsketch_g";

      # invocation lines
$invocation_lines

  commands:
      # external invocation lines
$external_invocation_lines

  reports:
$report_lines
}
EOHIPPUS

    my $save_result = $self->save_runfile($runfile_data, $result);

    return $result;
}

sub deactivate
{
    my $self = shift;
    my $deactivate = shift;

    my $result = DCAPI::Result->new(api => $self,
                                    status => 1,
                                    success => 1,
                                    data => { });

    # deactivate = true means all;
    if (Util::is_json_boolean($deactivate) && $deactivate)
    {
        $self->log("Deactivating all activations: %s", $self->activations());

        $result->add_data_key('deactivate', ['deactivate', $_], 1)
         foreach keys %{$self->activations()};

        %{$self->activations()} = ();
    }
    # deactivate = sketch means all activations of the sketch;
    elsif (ref $deactivate eq '')
    {
        my $d = delete $self->activations()->{$deactivate};

        unless ($d)
        {
            $d = [];
            foreach my $sketch (sort keys %{$self->activations()})
            {
                my @pushback;
                foreach my $spec (@{$self->activations()->{$sketch}})
                {
                    my $spec_identifier = Util::hashref_search($spec, qw/identifier/);
                    if (defined $spec_identifier && $spec_identifier eq $deactivate)
                    {
                        $self->log4("Deactivating activation %s that matched identifier '$deactivate'", $spec);
                    }
                    else
                    {
                        push @pushback, $spec;
                    }
                }
                $self->activations()->{$sketch} = \@pushback;
            }
        }

        $result->add_data_key('deactivate', ['deactivate', $deactivate], 1);

        $self->log("Deactivating all activations that match $deactivate: %s", $d);
    }
    elsif (ref $deactivate eq 'HASH' &&
           exists $deactivate->{sketch} &&
           exists $self->activations()->{$deactivate->{sketch}})
    {
        if (exists $deactivate->{position})
        {
            my $d = delete $self->activations()->{$deactivate->{sketch}}->[$deactivate->{position}];
            $result->add_data_key('deactivate', ['deactivate', $deactivate->{sketch}, $deactivate->{position}], 1);
            $self->log("Deactivating activation %s of %s: %s",
                       $deactivate->{position},
                       $deactivate->{sketch},
                       $d);
        }
    }

    $self->save_vardata();

    return $result;
}

sub regenerate_index
{
    my $self = shift;
    my $request = shift; # the repodir

    my $result;

    foreach my $repodir (@{$self->recognized_sources()})
    {
        next if ref $request ne ''; # must be a scalar
        next if $request ne $repodir; # must be the specific repo

        $result = DCAPI::Repo::make_inv_file($self, $repodir);
        last if $result;
    }

    if (defined $result)
    {
        $result->add_error('repodir', "Did not find the repodir")
         unless $result && $result->success();
    }

    return $result;
}

sub run_cf
{
    my $self = shift @_;
    my $data = shift @_;

    my ($fh, $filename) = tempfile( "./cf-agent-run-XXXX", TMPDIR => 1 );
    print $fh $data;
    close $fh;
    $self->log5("Running %s -KIf %s with data =\n%s",
                $self->cfagent(),
                $filename,
                $data);
    open my $pipe, '-|', $self->cfagent(), -KIf => $filename;
    return unless $pipe;
    while (<$pipe>)
    {
        chomp;
        next if m/Running full policy integrity checks/;
        $self->log3($_);
    }
    unlink $filename;

    return $?;
}

sub run_cf_promises
{
    my $self = shift @_;
    my $promises = shift @_;

    my $policy_template = <<'EOHIPPUS';
body common control
{
  bundlesequence => { "run" };
}

bundle agent run
{
%s
}

# from cfengine_stdlib
body copy_from no_backup_cp(from)
{
    source      => "$(from)";
    copy_backup => "false";
}

body perms m(mode)
{
    mode   => "$(mode)";
}

body delete tidy
{
    dirlinks => "delete";
    rmdirs   => "true";
}

body depth_search recurse_sketch
{
    include_basedir => "true";
    depth => "inf";
    xdev  => "false";
}

body file_select all
{
    leaf_name => { ".*" };
    file_result => "leaf_name";
}

EOHIPPUS

    my $policy = sprintf($policy_template,
                         join("\n",
                              map { "$_:\n$promises->{$_}\n" }
                              sort keys %$promises));
    return $self->run_cf($policy);
}

sub log_mode
{
    my $self = shift @_;
    return Util::hashref_search($self->config(), qw/log/) || 'STDERR';
}

sub log_level
{
    my $self = shift @_;
    return 0+(Util::hashref_search($self->config(), qw/log_level/)||0);
}

sub log
{
    my $self = shift @_;
    return $self->log_int(1, @_);
}

sub log2
{
    my $self = shift @_;
    return $self->log_int(2, @_);
}

sub log3
{
    my $self = shift @_;
    return $self->log_int(3, @_);
}

sub log4
{
    my $self = shift @_;
    return $self->log_int(4, @_);
}

sub log5
{
    my $self = shift @_;
    return $self->log_int(5, @_);
}

sub log_int
{
    my $self = shift @_;
    my $log_level = shift @_;

    return unless $self->log_level() >= $log_level;

    my $varlog = 0;
    my $close_out_fh = 1;
    my $out_fh;
    if (ref $self->log_mode() eq 'ARRAY')
    {
        $close_out_fh = 0;
        $varlog = 1;
        undef $out_fh;
    }
    elsif ($self->log_mode() eq 'STDERR')
    {
        $close_out_fh = 0;
        $out_fh = \*STDERR;
    }
    elsif ($self->log_mode() eq 'STDOUT')
    {
        $close_out_fh = 0;
        $out_fh = \*STDOUT;
    }
    elsif ($self->log_mode() eq 'pretty')
    {
        $close_out_fh = 0;
        $out_fh = \*STDERR;
    }
    else
    {
        my $f = $self->log_mode();
        open $out_fh, '>>', $f or warn "Could not append to log file $f: $!";
    }

    my $prefix;
    foreach my $level (1..4)    # probe up to 4 levels to find the real caller
    {
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray,
            $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller($level);

        $prefix = sprintf ('%s(%s:%s): ', $subroutine, basename($filename), $line);
        last unless $subroutine eq '(eval)';
    }

    my @plist;
    foreach (@_)
    {
        if (ref $_ eq 'ARRAY' || ref $_ eq 'HASH')
        {
            # we want to log it anyhow
            eval { push @plist, $self->encode($_) };
        }
        else
        {
            push @plist, $_;
        }
    }

    if ($out_fh)
    {
        if ($self->log_mode() eq 'pretty')
        {
            # In 'pretty' mode, don't print the suffix and color the output
            Util::message($prefix);
            Util::message(@plist);
        }
        else
        {
            print $out_fh $prefix;
            printf $out_fh @plist;
        }
        print $out_fh "\n";

        close $out_fh if $close_out_fh;
    }
    elsif ($varlog)
    {
        push @{$self->log_mode()}, [ $prefix, @plist ];
    }
}

sub decode { shift; CODER->decode(@_) };
sub encode { shift; CODER->encode(@_) };
sub cencode { shift; CAN_CODER->encode(@_) };
sub cencode_pretty { shift; CAN_CODER->pretty->encode(@_) };

sub dump_encode { shift; use Data::Dumper; return Dumper([@_]); }

sub load_raw
{
    my $self = shift @_;
    my $f    = shift @_;
    return $self->load_int($f, 1);
}

sub load
{
    my $self = shift @_;
    my $f    = shift @_;
    return $self->load_int($f, 0);
}

sub load_int
{
    my $self = shift @_;
    my $f    = shift @_;
    my $raw  = shift @_;

    return (undef, "Fatal: trying to load an undefined value") unless defined $f;
    return (undef, "Fatal: bad JSON data or empty file") unless length $f;

    my @j;

    my $try_eval;
    eval
    {
        $try_eval = $self->decode($f);
    };

    if ($try_eval)              # detect inline content, must be proper JSON
    {
        return ($try_eval);
    }

    chomp $f;

    if (Util::is_resource_local($f))
    {
        my $multiline = 1;
        my $j;
        if ($f eq '-')
        {
            $j = \*STDIN;
            $multiline = 0;
        }
        else
        {
            unless (open($j, '<', $f) && $j)
            {
                return (undef, "Could not inspect $f: $!");
            }
        }

        while (<$j>)
        {
            push @j, $_;
            last unless $multiline;
        }
    }
    else
    {
        my $j = Util::get_remote($f);

        defined $j or return (undef, "Unable to retrieve $f");

        @j = split "\n", $j;
    }

    if (scalar @j)
    {
        chomp @j;
        s/\n//g foreach @j;
        s/^\s*(#|\/\/).*//g foreach @j;

        if ($raw)
        {
            return (\@j);
        }
        else
        {
            return ($self->decode(join '', @j));
        }
    }

    return (undef, "No data was loaded from $f");
}

sub exit_error
{
    my $self = shift;
    if (ref $_[0] eq 'DCAPI::Result')
    {
        shift->out();
    }
    else
    {
        DCAPI::Result->new(api => $self,
                           status => 0,
                           success => 0,
                           errors => \@_)
             ->out();
    }
    exit $ENV{NOIGNORE} ? 1 : 0;
}

sub dispatch
{
    my $self = shift @_;
    my $data = shift @_;
    my $log = shift @_;

    my $debug = Util::hashref_search($data, qw/debug/);
    my $version = Util::hashref_search($data, qw/dc_api_version/);
    my $request = Util::hashref_search($data, qw/request/);

    my $selftest = Util::hashref_search($request, qw/selftest/);
    my $selftests = Util::hashref_search($request, qw/selftests/);

    my $test = Util::hashref_search($request, qw/test/);
    my $coverage = Util::hashref_search($request, qw/coverage/);

    my $list = Util::hashref_search($request, qw/list/);
    my $search = Util::hashref_search($request, qw/search/);
    my $describe = Util::hashref_search($request, qw/describe/);
    my $count_only = Util::hashref_search($request, qw/count_only/);

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
    my $regenerate_index = Util::hashref_search($request, qw/regenerate_index/);

    if ($debug)
    {
        push @$log, $self->data_dump();
    }

    unless (defined $version && $version eq $self->version())
    {
        $self->exit_error("Sorry, I can't handle broken JSON, or a missing or incorrect DC API Version: " . $self->version() . " vs. " . ($version||'???') , @$log);
    }

    unless (defined $request)
    {
        $self->exit_error("No request provided.", @$log);
    }

    my $result;

    if (defined $selftest)
    {
        $result = $self->selftest($selftest);
    }
    elsif (defined $selftests)
    {
        $result = $self->selftests();
    }
    elsif (defined $test)
    {
        $result = $self->test($test, { test => 1, coverage => $coverage });
    }
    elsif (defined $list)
    {
        $result = $self->list($list, { describe => $describe, count_only => $count_only });
    }
    elsif (defined $search)
    {
        $result = $self->search($search, { describe => $describe, count_only => $count_only });
    }
    elsif (defined $describe)
    {
        $result = $self->describe($describe);
    }
    elsif (defined $install)
    {
        $result = $self->install($install);
    }
    elsif (defined $uninstall)
    {
        $result = $self->uninstall($uninstall);
    }
    elsif (defined $compositions)
    {
        $result = DCAPI::Result->new(api => $self,
                                     status => 1,
                                     success => 1,
                                     data => {compositions => $self->compositions()});
    }
    elsif (defined $compose)
    {
        $result = $self->compose($compose);
    }
    elsif (defined $decompose)
    {
        $result = $self->decompose($decompose);
    }
    elsif (defined $activations)
    {
        $result = DCAPI::Result->new(api => $self,
                                     status => 1,
                                     success => 1,
                                     data=> {activations => $self->activations()});
    }
    elsif (defined $activate)
    {
        $result = $self->activate($activate, { compose => $compose });
    }
    elsif (defined $deactivate)
    {
        $result = $self->deactivate($deactivate);
    }
    elsif (defined $definitions)
    {
        $result = DCAPI::Result->new(api => $self,
                                     status => 1,
                                     success => 1,
                                     data=> {definitions => $self->definitions()});
    }
    elsif (defined $define)
    {
        $result = $self->define($define);
    }
    elsif (defined $undefine)
    {
        $result = $self->undefine($undefine);
    }
    elsif (defined $environments)
    {
        $result = DCAPI::Result->new(api => $self,
                                     status => 1,
                                     success => 1,
                                     data=> {environments => $self->environments()});
    }
    elsif (defined $define_environment)
    {
        $result = $self->define_environment($define_environment);
    }
    elsif (defined $undefine_environment)
    {
        $result = $self->undefine_environment($undefine_environment);
    }
    elsif (defined $validations)
    {
        $result = DCAPI::Result->new(api => $self,
                                     status => 1,
                                     success => 1,
                                     data=> {validations => $self->validations()});
    }
    elsif (defined $define_validation)
    {
        $result = $self->define_validation($define_validation);
    }
    elsif (defined $undefine_validation)
    {
        $result = $self->undefine_validation($undefine_validation);
    }
    elsif (defined $validate)
    {
        $result = $self->validate($validate);
    }
    elsif (defined $regenerate)
    {
        $result = $self->regenerate($regenerate);
    }
    elsif ($regenerate_index)           # must be true
    {
        $result = $self->regenerate_index($regenerate_index);
    }
    else
    {
        $result = DCAPI::Result->new(api => $self,
                                     status => 1,
                                     success => 1,
                                     log => [ "Nothing to do, but we're OK, thanks for asking." ]);
    }

    return $result;
}

1;
