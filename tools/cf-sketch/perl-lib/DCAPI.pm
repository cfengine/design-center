package DCAPI;

use strict;
use warnings;

use JSON::PP;
use File::Which;
use File::Basename;
use File::Temp qw/tempfile tempdir /;

use DCAPI::Repo;

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
has definitions => ( is => 'rw', default => sub { {} });
has activations => ( is => 'rw', default => sub { {} });
has environments => ( is => 'rw', default => sub { {} });

has warnings => ( is => 'ro', default => sub { {} } );

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

sub set_config
{
 my $self = shift @_;
 my $file = shift @_;

 $self->config($self->load($file));

 my @sources = @{(Util::hashref_search($self->config(), qw/recognized_sources/) || [])};
 $self->log5("Adding recognized source $_") foreach @sources;
 push @{$self->recognized_sources()}, @sources;

 my @repos = @{(Util::hashref_search($self->config(), qw/repolist/) || [])};
 $self->log5("Adding recognized repo $_") foreach @repos;
 push @{$self->repos()}, @repos;

 foreach my $location (@{$self->repos()}, @{$self->recognized_sources()})
 {
  next unless Util::is_resource_local($location);

  eval
  {
   $self->load_repo($location);
  };

  if ($@)
  {
   push @{$self->warnings()->{$location}}, $@;
  }
 }

 my $vardata_file = Util::hashref_search($self->config(), qw/vardata/);

 if ($vardata_file)
 {
  $vardata_file = glob($vardata_file);
  $self->log("Loading vardata file $vardata_file");
  $self->vardata($vardata_file);
  if (!(-f $vardata_file && -w $vardata_file && -r $vardata_file))
  {
   $self->log("Creating missing vardata file $vardata_file");
   my @save_warnings = $self->save_vardata();

   push @{$self->warnings()->{vardata}}, @save_warnings
    if scalar @save_warnings;
  }

  my ($v_data, @v_warnings) = $self->load($vardata_file);
  push @{$self->warnings()->{vardata}}, @v_warnings
   if scalar @v_warnings;

  if (ref $v_data ne 'HASH')
  {
   push @{$self->warnings()->{$vardata_file}}, "vardata is not a hash";
  }
  elsif (!exists $v_data->{activations})
  {
   push @{$self->warnings()->{$vardata_file}}, "vardata has no 'activations'";
  }
  elsif (!exists $v_data->{definitions})
  {
   push @{$self->warnings()->{$vardata_file}}, "vardata has no 'definitions'";
  }
  elsif (!exists $v_data->{environments})
  {
   push @{$self->warnings()->{$vardata_file}}, "vardata has no 'environments'";
  }
  else
  {
   $self->log("Successfully loaded vardata file $vardata_file");
   $self->activations($v_data->{activations});
   $self->definitions($v_data->{definitions});
   $self->environments($v_data->{environments});
  }
 }
 else
 {
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
 open my $vfh, '>', $vardata_file
  or return "Vardata file $vardata_file could not be created: $!";

 print $vfh $self->cencode($data);
 close $vfh;

 return;
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
  curl => $self->curl(),
  warnings => $self->warnings(),
  repolist => $self->repos(),
  recognized_sources => $self->recognized_sources(),
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

 my %ret;
 foreach my $location (@$repos)
 {
  $self->log("Searching location %s for terms %s",
            $location,
            $term_data);
  my $repo = $self->load_repo($location);
  my @list = map { $_->name() } $repo->list($term_data);
  $ret{$repo->location()} = [ @list ];
 }

 return \%ret;
}

sub sketch_api
{
 my $self = shift;
 my $sketches_top = shift;
 my $sources = shift;

 $sketches_top = { $sketches_top => undef } unless ref $sketches_top eq 'HASH';

 my %ret;
 my @repos = defined $sources ? (@$sources) : ($self->all_repos());
 foreach my $location (@repos)
 {
  my %sketches = %$sketches_top;
  my $repo = $self->load_repo($location);
  $ret{$repo->location()} = $repo->sketch_api(\%sketches);
 }

 return \%ret;
}

sub install
{
 my $self = shift;
 my $install = shift;

 my %ret;

 # we don't accept strings, the sketches to be installed must be in an array

 if (ref $install eq 'HASH')
 {
  $install = [ $install ];
 }

 if (ref $install ne 'ARRAY')
 {
  return (undef, "Invalid install command");
 }

 my @warnings;
 my @install_log;

 INSTALLER:
 foreach my $installer (@$install)
 {
  my %d;
  foreach my $varname (qw/sketch source dest/)
  {
   my $v = Util::hashref_search($installer, $varname);
   unless (defined $v)
   {
    push @{$self->warnings()->{''}}, "Installer command was missing key '$varname'";
    next INSTALLER;
   }
   $d{$varname} = $v;
  }

  # copy optional install criteria
  foreach my $varname (qw/version/)
  {
   my $v = Util::hashref_search($installer, $varname);
   next unless defined $v;
   $d{$varname} = $v;
  }

  my $location = $d{dest};
  my $drepo;
  my $srepo;

  eval
  {
   $drepo = $self->load_repo($d{dest});
   $srepo = $self->load_repo($d{source});
  };

  if ($@)
  {
   push @{$self->warnings()->{defined $drepo ? $d{source} : $d{dest}}}, $@;
  }

  next INSTALLER unless defined $drepo;
  next INSTALLER unless defined $srepo;


  if ($drepo->find_sketch($d{sketch}))
  {
   push @{$self->warnings()->{$d{source}}},
    "Sketch $d{sketch} is already in dest repo; you must uninstall it first";
   next INSTALLER;
  }

  my $sketch = $srepo->find_sketch($d{sketch}, $d{version});

  unless (defined $sketch)
  {
   push @{$self->warnings()->{$d{source}}},
    "Sketch $d{sketch} could not be found in source repo";
   next INSTALLER;
  }

  $self->log("Installing sketch $d{sketch} from $d{source} into $d{dest}");

  $ret{$d{dest}} = $drepo->install($srepo, $sketch);
 }

 return (\%ret, $self->warnings());
}

sub uninstall
{
 my $self = shift;
 my $uninstall = shift;

 my %ret;

 # we don't accept strings, the sketches to be installed must be in an array

 if (ref $uninstall eq 'HASH')
 {
  $uninstall = [ $uninstall ];
 }

 if (ref $uninstall ne 'ARRAY')
 {
  return (undef, "Invalid uninstall command");
 }

 my @warnings;
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
    push @{$self->warnings()->{''}}, "Uninstaller command was missing key '$varname'";
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

 if (ref $define ne 'HASH')
 {
  return (undef, "Invalid define command");
 }

 foreach my $dkey (keys %$define)
 {
  $self->definitions()->{$dkey} = $define->{$dkey};
 }

 $self->save_vardata();
}

sub undefine
{
 my $self = shift;
 my $undefine = shift;

 if (ref $undefine ne 'ARRAY')
 {
  return (undef, "Invalid undefine command");
 }

 foreach my $ukey (@$undefine)
 {
  delete $self->definitions()->{$ukey};
 }

 $self->save_vardata();
}

sub define_environment
{
 my $self = shift;
 my $define_environment = shift;

 if (ref $define_environment ne 'HASH')
 {
  return (undef, "Invalid define_environment command");
 }

 foreach my $dkey (keys %$define_environment)
 {
  $self->environments()->{$dkey} = $define_environment->{$dkey};
 }

 $self->save_vardata();
}

sub undefine_environment
{
 my $self = shift;
 my $undefine_environment = shift;

 if (ref $undefine_environment ne 'ARRAY')
 {
  return (undef, "Invalid undefine_environment command");
 }

 foreach my $ukey (@$undefine_environment)
 {
  delete $self->environments()->{$ukey};
 }

 $self->save_vardata();
}

sub activate
{
 my $self = shift;
 my $activate = shift;

 if (ref $activate ne 'HASH')
 {
  return (undef, "Invalid activate command");
 }

 # TODO: handle activation request in form
 # sketch: [ definition1, definition2, ... ]
 foreach my $akey (keys %$activate)
 {
  die $self->encode($activate->{$akey});
 }

 $self->save_vardata();
}

sub deactivate
{
 my $self = shift;
 my $deactivate = shift;

 # TODO: handle three cases:

 # deactivate = true means all;

 # deactivate = sketch means all activations of the sketch;

 # deactivate = activation instance means a specific activation of the
 # sketch

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

 # only recognize one log mode for now
 return unless $self->log_mode() eq 'STDERR';
 return unless $self->log_level() >= $log_level;

 my $prefix;
 foreach my $level (1..4) # probe up to 4 levels to find the real caller
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

 print STDERR $prefix;
 printf STDERR @plist;
 print STDERR "\n";
};

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
};

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

 if ($try_eval) # detect inline content, must be proper JSON
 {
  return ($try_eval);
 }
 elsif (Util::is_resource_local($f))
 {
  my $j;
  unless (open($j, '<', $f) && $j)
  {
   return (undef, "Could not inspect $f: $!");
  }

  @j = <$j>;
 }
 else
 {
  my ($j, $error) = $self->curl_GET($f);

  defined $error and return (undef, $error);
  defined $j or return (undef, "Unable to retrieve $f");

  @j = @$j;
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
