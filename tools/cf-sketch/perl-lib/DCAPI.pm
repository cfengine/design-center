package DCAPI;

use strict;
use warnings;

use JSON::PP;
use File::Which;
use File::Basename;
use File::Temp qw/tempfile tempdir /;

use DCAPI::Repo;
use DCAPI::Activation;

use constant API_VERSION => '0.0.1';
use constant CODER => JSON::PP->new()->allow_barekey()->relaxed()->utf8()->allow_nonref();
use constant CAN_CODER => JSON::PP->new()->canonical()->utf8()->allow_nonref();

use Mo qw/build default builder coerce is required/;

# has name2 => ( builder => 'name_builder' );
# has name4 => ( required => 1 );

has version => ( is => 'ro', default => sub { API_VERSION } );

has config => ( );

has curl => ( is => 'ro', default => sub { which('curl') } );
has cfagent => (
                is => 'ro',
                default => sub
                {
                    my $c = which('cf-agent');

                    $c = '/var/cfengine/bin/cf-agent' unless $c;

                    return $c if -x $c;

                    return undef;
                }
               );

has repos => ( is => 'ro', default => sub { [] } );
has recognized_sources => ( is => 'ro', default => sub { [] } );
has vardata => ( is => 'rw');
has runfile => ( is => 'ro', default => sub { {} } );
has definitions => ( is => 'rw', default => sub { {} });
has activations => ( is => 'rw', default => sub { {} });
has environments => ( is => 'rw', default => sub { { default =>
                                                     {
                                                      test => 0,
                                                      verbose => 0,
                                                      activated => 1,
                                                     }
                                                 }
                                               });

has warnings => ( is => 'ro', default => sub { {} } );
has cfengine_min_version => ( is => 'ro', required => 1 );
has cfengine_version => ( is => 'rw' );

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
    my $bin = $self->cfagent();
    my $cfv = `$bin -V`;
    if ($cfv =~ m/\s+(\d+\.\d+\.\d+)/) {
        $self->cfengine_version($1);
    }
}

sub set_config
{
    my $self = shift @_;
    my $file = shift @_;

    $self->config($self->load($file));

    my $runfile = Util::hashref_search($self->config(), qw/runfile/);

    if (ref $runfile ne 'HASH') {
        push @{$self->warnings()->{runfile}}, "runfile is not a hash";
    } else {
        %{$self->runfile()} = %$runfile;
        push @{$self->warnings()->{runfile}}, "runfile has no location"
         unless exists $self->runfile()->{location};
        push @{$self->warnings()->{runfile}}, "runfile has no standalone boolean"
         unless exists $self->runfile()->{standalone};
        push @{$self->warnings()->{runfile}}, "runfile has no relocate_path parameter"
         unless exists $self->runfile()->{relocate_path};
    }

    my @sources = @{(Util::hashref_search($self->config(), qw/recognized_sources/) || [])};
    $self->log5("Adding recognized source $_") foreach @sources;
    push @{$self->recognized_sources()}, @sources;

    my @repos = @{(Util::hashref_search($self->config(), qw/repolist/) || [])};
    $self->log5("Adding recognized repo $_") foreach @repos;
    push @{$self->repos()}, @repos;

    foreach my $location (@{$self->repos()}, @{$self->recognized_sources()}) {
        next unless Util::is_resource_local($location);

        eval
        {
            $self->load_repo($location);
        };

        if ($@) {
            push @{$self->warnings()->{$location}}, $@;
        }
    }

    my $vardata_file = Util::hashref_search($self->config(), qw/vardata/);

    if ($vardata_file) {
        $vardata_file = glob($vardata_file);
        $self->log("Loading vardata file $vardata_file");
        $self->vardata($vardata_file);
        if (!(-f $vardata_file && -w $vardata_file && -r $vardata_file)) {
            $self->log("Creating missing vardata file $vardata_file");
            my @save_warnings = $self->save_vardata();

            push @{$self->warnings()->{vardata}}, @save_warnings
             if scalar @save_warnings;
        }

        my ($v_data, @v_warnings) = $self->load($vardata_file);
        push @{$self->warnings()->{vardata}}, @v_warnings
         if scalar @v_warnings;

        if (ref $v_data ne 'HASH') {
            push @{$self->warnings()->{$vardata_file}}, "vardata is not a hash";
        } elsif (!exists $v_data->{activations}) {
            push @{$self->warnings()->{$vardata_file}}, "vardata has no 'activations'";
        } elsif (!exists $v_data->{definitions}) {
            push @{$self->warnings()->{$vardata_file}}, "vardata has no 'definitions'";
        } elsif (!exists $v_data->{environments}) {
            push @{$self->warnings()->{$vardata_file}}, "vardata has no 'environments'";
        } else {
            $self->log("Successfully loaded vardata file $vardata_file");
            $self->activations($v_data->{activations});
            $self->definitions($v_data->{definitions});
            $self->environments($v_data->{environments});
        }
    } else {
        push @{$self->warnings()->{vardata}}, "No vardata file specified";
    }

    my $w = $self->warnings();
    return scalar keys %$w ? (1,  $w) : (1);
}

sub save_vardata
{
    my $self = shift;

    my $data = {
                activations => $self->activations,
                definitions => $self->definitions,
                environments => $self->environments,
               };
    my $vardata_file = $self->vardata();

    $self->log("Saving vardata file $vardata_file");
    open my $fh, '>', $vardata_file
     or return "Vardata file $vardata_file could not be created: $!";

    print $fh $self->cencode($data);
    close $fh;

    return 1;
}

sub save_runfile
{
    my $self = shift @_;
    my $data = shift @_;

    my $runfile = glob($self->runfile()->{location});

    $self->log("Saving runfile $runfile");
    open my $fh, '>', $runfile
     or return "Run file $runfile could not be created: $!";

    print $fh $data;
    close $fh;

    return 1;
}

sub is_ok_cfengine_version
{
    my $self = shift @_;
    my $req = shift @_ || $self->cfengine_min_version();

    return 0 unless defined $req;

    return $req le $self->cfengine_version();
}

sub all_repos
{
    my $self = shift;
    my $sources_first = shift;

    if ($sources_first) {
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

    unless (exists $repos{$repo}) {
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
     curl => $self->curl(),
     warnings => $self->warnings(),
     repolist => $self->repos(),
     recognized_sources => $self->recognized_sources(),
     vardata => $self->vardata(),
     runfile => $self->runfile(),
     definitions => $self->definitions(),
     activations => $self->activations(),
     environments => $self->environments(),
    };
}

sub search
{
    my $self = shift;
    return $self->list_int($self->recognized_sources(), @_);
}

sub list
{
    my $self = shift;
    return $self->list_int($self->repos(), @_);
}

sub list_int
{
    my $self = shift;
    my $repos = shift;
    my $term_data = shift;
    my $options = shift || {};

    my @full_list;
    my %ret;
    foreach my $location (@$repos) {
        $self->log("Searching location %s for terms %s",
                   $location,
                   $term_data);
        my $repo = $self->load_repo($location);
        my @list = map { $_->name() } $repo->list($term_data);
        $ret{$repo->location()} = [ @list ];
        push @full_list, @list;
    }

    return exists $options->{flatten} ? \@full_list : \%ret;
}

sub describe
{
    my $self = shift;
    my $sketches_top = shift;
    my $sources = shift;
    my $firstfound = shift;

    $sketches_top = { $sketches_top => undef } unless ref $sketches_top eq 'HASH';

    my %ret;
    my @repos = defined $sources ? (@$sources) : ($self->all_repos());
    foreach my $location (@repos) {
        my %sketches = %$sketches_top;
        my $repo = $self->load_repo($location);
        my $found = $repo->describe(\%sketches, $firstfound);
        return $found if ($found && $firstfound);
        $ret{$repo->location()} = $found;
    }

    return \%ret;
}

sub install
{
    my $self = shift;
    my $install = shift;

    my %ret;

    # we don't accept strings, the sketches to be installed must be in an array

    if (ref $install eq 'HASH') {
        $install = [ $install ];
    }

    if (ref $install ne 'ARRAY') {
        return (undef, "Invalid install command");
    }

    my @warnings;
    my @install_log;

 INSTALLER:
    foreach my $installer (@$install) {
        my %d;
        foreach my $varname (qw/sketch source target/) {
            my $v = Util::hashref_search($installer, $varname);
            unless (defined $v)
            {
                push @{$self->warnings()->{''}}, "Installer command was missing key '$varname'";
                next INSTALLER;
            }
            $d{$varname} = $v;
        }

        # copy optional install criteria
        foreach my $varname (qw/version/) {
            my $v = Util::hashref_search($installer, $varname);
            next unless defined $v;
            $d{$varname} = $v;
        }

        my $location = $d{target};
        my $drepo;
        my $srepo;

        eval
        {
            $drepo = $self->load_repo($d{target});
            $srepo = $self->load_repo($d{source});
        };

        if ($@) {
            push @{$self->warnings()->{defined $drepo ? $d{source} : $d{target}}}, $@;
        }

        next INSTALLER unless defined $drepo;
        next INSTALLER unless defined $srepo;

        if ($drepo->find_sketch($d{sketch})) {
            push @{$self->warnings()->{$d{source}}},
             "Sketch $d{sketch} is already in target repo; you must uninstall it first";
            next INSTALLER;
        }

        my $sketch = $srepo->find_sketch($d{sketch}, $d{version});

        unless (defined $sketch)
        {
            push @{$self->warnings()->{$d{source}}},
             "Sketch $d{sketch} could not be found in source repo";
            next INSTALLER;
        }

        my ($depcheck, @dep_warnings) = $sketch->resolve_dependencies(install => 1,
                                                                      source => $d{source},
                                                                      target => $d{target});

        return ($depcheck, @dep_warnings)
         unless $depcheck;

        $self->log("Installing sketch $d{sketch} from $d{source} into $d{target}");

        $ret{$d{target}} = $drepo->install($srepo, $sketch);
    }

    return (\%ret, $self->warnings());
}

sub uninstall
{
    my $self = shift;
    my $uninstall = shift;

    my %ret;

    # we don't accept strings, the sketches to be installed must be in an array

    if (ref $uninstall eq 'HASH') {
        $uninstall = [ $uninstall ];
    }

    if (ref $uninstall ne 'ARRAY') {
        return (undef, "Invalid uninstall command");
    }

    my @warnings;
    my @uninstall_log;

 UNINSTALLER:
    foreach my $uninstaller (@$uninstall) {
        my %d;
        foreach my $varname (qw/sketch target/) {
            my $v = Util::hashref_search($uninstaller, $varname);
            unless (defined $v)
            {
                push @{$self->warnings()->{''}}, "Uninstaller command was missing key '$varname'";
                next UNINSTALLER;
            }
            $d{$varname} = $v;
        }

        # copy optional install criteria
        foreach my $varname (qw/version/) {
            my $v = Util::hashref_search($uninstaller, $varname);
            next unless defined $v;
            $d{$varname} = $v;
        }

        my $repo;

        eval
        {
            $repo = $self->load_repo($d{target});
        };

        if ($@) {
            push @{$self->warnings()->{$d{target}}}, $@;
        }

        next UNINSTALLER unless defined $repo;

        my $sketch = $repo->find_sketch($d{sketch});

        unless ($sketch)
        {
            push @{$self->warnings()->{$d{target}}},
             "Sketch $d{sketch} is not in target repo; you must install it first";
            next UNINSTALLER;
        }

        $self->log("Uninstalling sketch $d{sketch} from " . $sketch->location());

        $ret{$d{target}} = $repo->uninstall($sketch);
    }

    return (\%ret, $self->warnings());
}

sub define
{
    my $self = shift;
    my $define = shift;

    if (ref $define ne 'HASH') {
        return (undef, "Invalid define command");
    }

    foreach my $dkey (keys %$define) {
        $self->definitions()->{$dkey} = $define->{$dkey};
    }

    $self->save_vardata();
}

sub undefine
{
    my $self = shift;
    my $undefine = shift;

    if (ref $undefine ne 'ARRAY') {
        return (undef, "Invalid undefine command");
    }

    foreach my $ukey (@$undefine) {
        delete $self->definitions()->{$ukey};
    }

    $self->save_vardata();
}

sub define_environment
{
    my $self = shift;
    my $define_environment = shift;

    if (ref $define_environment ne 'HASH') {
        return (undef, "Invalid define_environment command");
    }

    foreach my $dkey (keys %$define_environment) {
        my $spec = $define_environment->{$dkey};

        if (ref $spec ne 'HASH') {
            return (undef, "Invalid environment spec under $dkey");
        }

        foreach my $required (qw/activated test verbose/) {
            return (undef, "Invalid environment spec $dkey: missing key $required")
             unless exists $spec->{$required};

            $spec->{$required} = ! ! $spec->{$required}
             if Util::is_json_boolean($spec->{$required});

            # only scalars are acceptable
            return (undef, "Invalid environment spec $dkey: non-scalar key $required")
             if (ref $spec->{$required});
        }

        $self->environments()->{$dkey} = $spec;
    }

    $self->save_vardata();
}

sub undefine_environment
{
    my $self = shift;
    my $undefine_environment = shift;

    if (ref $undefine_environment ne 'ARRAY') {
        return (undef, "Invalid undefine_environment command");
    }

    foreach my $ukey (@$undefine_environment) {
        delete $self->environments()->{$ukey};
    }

    $self->save_vardata();
}

sub activate
{
    my $self = shift;
    my $activate = shift;

    if (ref $activate ne 'HASH') {
        return (undef, "Invalid activate command");
    }

    # handle activation request in form
    # sketch: { environment:"run environment", target:"/my/repo", params: [definition1, definition2, ... ] }
    foreach my $sketch (keys %$activate) {
        my $spec = $activate->{$sketch};

        my ($verify, @warnings) = DCAPI::Activation::make_activation($self, $sketch, $spec);

        if ($verify) {
            $self->log("Activating sketch %s with spec %s", $sketch, $spec);
            my $cspec = $self->cencode($spec);
            if (exists $self->activations()->{$sketch}) {
                foreach (@{$self->activations()->{$sketch}}) {
                    if ($cspec eq $self->cencode($_)) {
                        return (undef, "Activation is already in place");
                    }
                }
            }

            push @{$self->activations()->{$sketch}}, $spec;
            $self->log("Activations for sketch %s are now %s",
                       $sketch,
                       $self->activations()->{$sketch});
        } else {
            return ($verify, @warnings);
        }
    }

    $self->save_vardata();
}

sub regenerate
{
    my $self = shift;
    my $regenerate = shift;

    my $relocate = $self->runfile()->{relocate_path};

    my @all_warnings;

    my @activations;                    # these are DCAPI::Activation objects
    my $acts = $self->activations();    # these are data structures
    foreach my $sketch (keys %$acts) {
        foreach my $spec (@{$acts->{$sketch}}) {
            # this is how the data structure is turned into a DCAPI::Activation object
            my ($activation, @warnings) = DCAPI::Activation::make_activation($self, $sketch, $spec);

            if (scalar @warnings) {
                push @all_warnings, @warnings;
                $self->log("Regenerate: verification warnings [@warnings]");
            }

            if ($activation) {
                my $sketch_obj = $activation->sketch();
                $self->log("Regenerate: adding activation of %s; spec %s", $sketch, $spec);
                push @activations, $activation;
            } else {
                return ($activation, @warnings);
            }
        }
    }

    # 1. determine includes from sketches, their dependencies, and namespaces
    my @inputs;
    foreach my $a (@activations) {
        push @inputs, $a->sketch()->get_inputs($relocate, 5);
        $self->log("Regenerate: adding inputs %s", \@inputs);
    }

    @inputs = Util::uniq(@inputs);
    my $inputs = join "\n", Util::make_var_lines('inputs', \@inputs, '', 0, 0);

    my $type_indent = ' ' x 2;
    my $context_indent = ' ' x 4;
    my $indent = ' ' x 6;

    # 2. make cfsketch_g and environment bundles with data
    my @data;
    my %environments;
    my $position = 1;

    foreach my $a (@activations) {
        $self->log("Regenerate: generating activation %s", $a->id());

        foreach my $p (@{$a->params()}) {
            if ($p->{type} eq 'environment') {
                $self->log("Regenerate: adding environment %s", $p);
                $environments{$p->{value}}++;
            }
            # we can't inline some types, so print them explicitly in the data bundle
            elsif (!$a->can_inline($p->{type})) {
                $self->log("Regenerate: adding explicit data %s", $p);
                my $line = join("\n",
                                sprintf("%s# %s '%s' from definition %s, activation %s",
                                        $indent,
                                        $p->{type},
                                        $p->{name},
                                        $p->{set},
                                        $a->id()),
                                map { "$indent$_" } Util::make_var_lines($a->id() . '_' . $p->{name},
                                                                         $p->{value},
                                                                         '',
                                                                         0,
                                                                         0));
                push @data, $line;
            }
        }
    }

    my $data_lines = join "\n\n", @data;

    my $environment_calls = '';
    my @environment_lines = ("# environment common bundles\n");
    foreach my $e (keys %environments) {
        my $print_e = $e;
        $print_e =~ s/\W/_/g;

        my @var_data;
        my @class_data;
        my $edata = $self->environments()->{$e};

        # ensure there's an "activated" class
        unless (exists $edata->{activated}) {
            $edata->{activated} = 1;
        }

        my @ekeys = sort keys %$edata;
        $edata->{env_vars} = \@ekeys;
        $edata->{env_vars_str} = join ' ', @ekeys;
        foreach my $v (sort keys %$edata) {
            my $print_v = $v;
            $print_v =~ s/\W/_/g;
            my $d = $edata->{$v};
            my $line = join("\n",
                            map { "$indent$_" }
                            Util::make_var_lines($print_v, $d, '', 0, 0));
            push @var_data, $line;

            # is it a scalar?
            if (ref $d eq '') {
                my $d_expression = $d;
                if ($d_expression eq '0' || $d_expression eq 'false' || $d_expression eq 'no') {
                    $d_expression = '!any';
                } elsif ($d_expression eq '1' || $d_expression eq 'true' || $d_expression eq 'yes') {
                    $d_expression = 'any';
                }

                $d_expression =~ s/[^a-zA-Z0-9_!&@@$|.()\[\]{}:]/_/g;

                push @class_data, sprintf('%s"runenv_%s_%s" expression => "%s";',
                                          $indent,
                                          $print_e,
                                          $print_v,
                                          $d_expression);
            }
        }

        push @environment_lines,
         sprintf("# environment %s\nbundle common %s\n{\n%s\n}\n",
                 $e, $print_e, join("\n",
                                    "${type_indent}vars:",
                                    @var_data,
                                    # don't insert classes: line if there's no classes
                                    (scalar @class_data ? "${type_indent}classes:" : ''),
                                    @class_data));

        $environment_calls .= "$indent\"$e\" usebundle => \"$print_e\";\n";
    }

    my $environment_lines = join "\n", @environment_lines;

    # 3. make cfsketch_run bundle with invocations
    my @invocation_lines;
    foreach my $a (@activations) {
        $self->log("Regenerate: generating activation call %s", $a->id());

        push @invocation_lines, sprintf('%srunenv_%s_%s::',
                                        $context_indent,
                                        $a->environment(),
                                        'activated');

        my $namespace = $a->sketch()->namespace();
        my $namespace_prefix = $namespace eq 'default' ? '' : "$namespace:";

        push @invocation_lines, sprintf('%s"%s" usebundle => %s%s(%s);',
                                        $indent,
                                        $a->id(),
                                        $namespace_prefix,
                                        $a->bundle(),
                                        $a->make_bundle_params());
    }

    my $standalone_lines = <<EOHIPPUS;
body common control
{
    bundlesequence => { "cfsketch_run" };
    inputs => { @(cfsketch_g.inputs) };
}
EOHIPPUS

    $standalone_lines = '' unless $self->runfile()->{standalone};

    my $invocation_lines = join "\n", @invocation_lines;

    my $runfile_data = <<EOHIPPUS;
$standalone_lines

$environment_lines

# activation data
bundle common cfsketch_g
{
  vars:
      # Files that need to be loaded for the activated sketches and
      # their dependencies.
      $inputs

$data_lines
}

bundle agent cfsketch_run
{
  methods:
    any::
      "cfsketch_g" usebundle => "cfsketch_g";
$environment_calls
$invocation_lines
}
EOHIPPUS

    my $save_result = $self->save_runfile($runfile_data);
    push @all_warnings, $save_result unless $save_result;

    return (! ! $save_result, @all_warnings);
}

sub deactivate
{
    my $self = shift;
    my $deactivate = shift;

    # deactivate = true means all;
    if (Util::is_json_boolean($deactivate) && $deactivate) {
        $self->log("Deactivating all activations: %s", $self->activations());
        %{$self->activations()} = ();
    }
    # deactivate = sketch means all activations of the sketch;
    elsif (ref $deactivate eq '') {
        $self->log("Deactivating all activations of $deactivate: %s",
                   delete $self->activations()->{$deactivate});
    } elsif (ref $deactivate eq 'HASH' &&
             exists $deactivate->{sketch} &&
             exists $self->activations()->{$deactivate->{sketch}}) {
        if (exists $deactivate->{position}) {
            $self->log("Deactivating activation %s of %s: %s",
                       $deactivate->{position},
                       $deactivate->{sketch},
                       delete $self->activations()->{$deactivate->{sketch}}->[$deactivate->{position}]);
        }
    }

    $self->save_vardata();
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
    while (<$pipe>) {
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

    # only recognize one log mode for now
    return unless $self->log_mode() eq 'STDERR';
    return unless $self->log_level() >= $log_level;

    my $prefix;
    foreach my $level (1..4)      # probe up to 4 levels to find the real caller
    {
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray,
            $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller($level);

        $prefix = sprintf ('%s(%s:%s): ', $subroutine, basename($filename), $line);
        last unless $subroutine eq '(eval)';
    }

    my @plist;
    foreach (@_) {
        if (ref $_ eq 'ARRAY' || ref $_ eq 'HASH') {
            # we want to log it anyhow
            eval { push @plist, $self->encode($_) };
        } else {
            push @plist, $_;
        }
    }

    print STDERR $prefix;
    printf STDERR @plist;
    print STDERR "\n";
}
;

sub decode { shift; CODER->decode(@_) };
sub encode { shift; CODER->encode(@_) };
sub cencode { shift; CAN_CODER->encode(@_) };

sub dump_encode { shift; use Data::Dumper; return Dumper([@_]); }

sub curl_GET { shift->curl('GET', @_) };

sub curl
{
    my $self = shift @_;
    my $mode = shift @_;
    my $url = shift @_;

    my $curl = $self->curl();

    my $run = <<EOHIPPUS;
$curl -s $mode $url |
EOHIPPUS

    $self->log("Running: $run\n");

    open my $c, $run or return (undef, "Could not run command [$run]: $!");

    return ([<$c>], undef);
}
;

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

    my @j;

    my $try_eval;
    eval
    {
        $try_eval = $self->decode($f);
    };

    if ($try_eval)                  # detect inline content, must be proper JSON
    {
        return ($try_eval);
    } elsif (Util::is_resource_local($f)) {
        my $j;
        unless (open($j, '<', $f) && $j)
        {
            return (undef, "Could not inspect $f: $!");
        }

        @j = <$j>;
    } else {
        my ($j, $error) = $self->curl_GET($f);

        defined $error and return (undef, $error);
        defined $j or return (undef, "Unable to retrieve $f");

        @j = @$j;
    }

    if (scalar @j) {
        chomp @j;
        s/\n//g foreach @j;
        s/^\s*(#|\/\/).*//g foreach @j;

        if ($raw) {
            return (\@j);
        } else {
            return ($self->decode(join '', @j));
        }
    }

    return (undef, "No data was loaded from $f");
}

sub ok
{
    my $self = shift;
    print $self->encode($self->make_ok(@_)), "\n";
}

sub exit_error
{
    shift->error(@_);
    exit 0;
}

sub error
{
    my $self = shift;
    print $self->encode($self->make_error(@_)), "\n";
}

sub make_ok
{
    my $self = shift;
    my $ok = shift;
    $ok->{success} = JSON::PP::true;
    $ok->{errors} ||= [];
    $ok->{warnings} ||= [];
    $ok->{log} ||= [];
    return { api_ok => $ok };
}

sub make_not_ok
{
    my $self = shift;
    my $nok = shift;
    $nok->{success} = JSON::PP::false;
    $nok->{errors} ||= shift @_;
    $nok->{warnings} ||= shift @_;
    $nok->{log} ||= shift @_;
    return { api_not_ok => $nok };
}

sub make_error
{
    my $self = shift;
    return { api_error => [@_] };
}

1;
