#!/usr/bin/env perl -w
#
# DesignCenter::Sketch
# Representation of a sketch
#
# Diego Zamboni <diego.zamboni@cfengine.com>
# Time-stamp: <2012-10-10 01:48:49 a10022>

package DesignCenter::Sketch;

use warnings;
use strict;
use Carp;
use Util;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;

use DesignCenter::JSON;
use DesignCenter::Config;

our $AUTOLOAD;                  # it's a package global

# Default data fields
my %fields = (
              name => undef,
              location => undef,
              json_data => undef,
             );

######################################################################

# Automatically generate setters/getters, i.e. MAGIC
sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";

  my $name = $AUTOLOAD;
  $name =~ s/.*://;             # strip fully-qualified portion

# Allow all fields
#  unless (exists $self->{_permitted}->{$name} ) {
#    croak "Can't access `$name' field in class $type";
#  }

  if (@_) {
    return $self->{$name} = shift;
  } else {
    return $self->{$name};
  }
}

sub new {
  my $class = shift;
  my %data = @_;
  # Data initialization
  my $self  = {
               _permitted => \%fields,
               %data,
              };

  # Convert myself into an object
  bless($self, $class);

  return $self;
}

sub load {
  my $self = shift;
  my $am_object = ref($self);
  my $dir    = $am_object ? $self->location : shift;
  my $topdir = shift;
  my $noparse = shift || 0;

  my $name = Util::is_resource_local($dir) ? File::Spec->catfile($dir, $CFSketch::SKETCH_DEF_FILE) : "$dir/" . $CFSketch::SKETCH_DEF_FILE;
  my $json = DesignCenter::JSON::load($name);

  my $info = {};
  my @messages;

  # stage 1: the data must be valid and a hash
  unless (defined $json && ref $json eq 'HASH')
    {
      push @messages, "Invalid JSON data";
    }

  # stage 2: check top-level manifest and metadata keys
  unless (scalar @messages)
    {
      # the manifest must be a hash
      push @messages, "Invalid manifest: must be { ... }" unless (exists $json->{manifest} && ref $json->{manifest} eq 'HASH');

      # the metadata must be a hash
      push @messages, "Invalid metadata: must be { ... }" unless (exists $json->{metadata} && ref $json->{metadata} eq 'HASH');

      # the interface must be an array
      push @messages, "Invalid interface: must be [ \"FILE.cf\" ]" unless (exists $json->{interface} && ref $json->{interface} eq 'ARRAY');
    }

  # stage 3: check metadata details
  unless (scalar @messages)
    {
      # need a 'depends' key that points to a hash
      push @messages, "Invalid dependencies structure in 'depends'" unless (exists $json->{metadata}->{depends}  &&
                                                                            ref $json->{metadata}->{depends}  eq 'HASH');

      foreach my $scalar (qw/name version license/) {
        push @messages, "Missing or undefined metadata element '$scalar'" unless $json->{metadata}->{$scalar};
      }

      foreach my $array (qw/authors tags/) {
        push @messages, "Missing, invalid, or undefined metadata array '$array'" unless ($json->{metadata}->{$array} &&
                                                                                       ref $json->{metadata}->{$array} eq 'ARRAY');
      }

      unless (scalar @messages)
        {
          push @messages, "'tags' metadata can't be empty" unless scalar @{$json->{metadata}->{tags}};
        }
    }

  # stage 4: check entry_point and interface
  unless (scalar @messages)
    {
      push @messages, "Missing 'entry_point'" unless exists $json->{entry_point};
    }

  # entry_point has to point to a file in the manifest or be null
  unless (scalar @messages || !defined $json->{entry_point}) {
    push @messages, "entry_point $json->{entry_point} not in manifest"
      unless exists $json->{manifest}->{$json->{entry_point}};
  }

  # we should not have any interface files that do NOT exist in the manifest
  unless (scalar @messages)
    {
      foreach (@{$json->{interface}}) {
        push @messages, "interface file '$_' not in manifest" unless exists $json->{manifest}->{$_};
      }
    }

  if (!scalar @messages)        # there are no errors, so go on...
    {
      my $name = $json->{metadata}->{name};
      $json->{dir} = DesignCenter::Config->fullpath || !Util::is_resource_local($dir) ? $dir : File::Spec->abs2rel( $dir, $topdir );
      $json->{fulldir} = $dir;
      $json->{file} = $name;
      if ($noparse ||
          !defined $json->{entry_point} ||
          verify_entry_point($name, $json)) {
        # note this name will be stringified even if it's not a string
        if ($am_object) {
          $self->json_data($json);
          # Also merge fields into the main object
          foreach my $k (keys %$json) {
            $self->$k($json->{$k});
          }
        }
        return $json;
      } else {
        Util::warning "Could not verify bundle entry point from $name\n" unless DesignCenter::Config->quiet;
      }
    } else {
      Util::warning "Could not load sketch definition from $name: [@{[join '; ', @messages]}]\n" unless DesignCenter::Config->quiet;
    }

  $self->json_data(undef) if $am_object;
  return undef;
}

sub verify_entry_point {
  my $name = shift;
  my $data = shift;
  use Carp qw/cluck/;

  my $dir       = $data->{fulldir};
  my $mft       = $data->{manifest};
  my $entry     = $data->{entry_point};
  my $interface = $data->{interface};

  unless (defined $entry && defined $interface)
    {
      return undef;
    }

  my $maincf = $entry;

  my $maincf_filename = Util::is_resource_local($dir) ? File::Spec->catfile($dir, $maincf) : "$dir/$maincf";

  my $meta = {
              file => basename($maincf_filename),
              dir => dirname($maincf_filename),
              fulldir => $dir,
              varlist => [
                         ],
             };

  my @mcf;
  my $mcf;

  if (exists $mft->{$maincf}) {
    if (Util::is_resource_local($dir)) {
      unless (-f $maincf_filename)
        {
          Util::warning "Could not find sketch $name entry point '$maincf_filename'\n" unless DesignCenter::Config->quiet;
          return 0;
        }

      unless (open($mcf, '<', $maincf_filename) && $mcf)
        {
          Util::warning "Could not open $maincf_filename: $!\n" unless DesignCenter::Config->quiet;
          return 0;
        }
      @mcf = <$mcf>;
      $mcf = join "\n", @mcf; # make sure the whole string is available
    } else {
      $mcf = Util::get_remote($maincf_filename);
      unless ($mcf)
        {
          Util::warning "Could not retrieve $maincf_filename: $!\n" unless DesignCenter::Config->quiet;
          return 0;
        }

      @mcf = split "\n", $mcf;
    }
  }

  my $tdir = tempdir( CLEANUP => 0 );
  my ($tfh, $tfilename) = tempfile( DIR => $tdir );

  if ($mcf !~ m/body\s+common\s+control.*bundlesequence/m) {
    print "Faking bundlesequence: collecting dependencies for $data->{metadata}->{name} from @{[sort keys %{$data->{metadata}->{depends}}]}\n"
      if DesignCenter::Config->veryverbose;
    my %dependencies = map { $_ => 1 } CFSketch::collect_dependencies($data->{metadata}->{depends});
    my @inputs = CFSketch::collect_dependencies_inputs(dirname($tfilename), \%dependencies);
    print "Faking bundlesequence: collected inputs [@inputs]\n"
      if DesignCenter::Config->veryverbose;
    my @p = DesignCenter::JSON::recurse_print([ Util::uniq(@inputs) ]);
    $mcf = sprintf('
  body common control {

    bundlesequence => { "cf_null" };
    inputs => %s;
}
', $p[0]->{value}) . $mcf;
  } else {
  }

  print "PARSING:\n$mcf\n\n" if DesignCenter::Config->veryverbose;

  print $tfh $mcf;
  close $tfh;

  my $pb = CFSketch::cfengine_binary('cf-promises');
  my $tline = "$pb --parse-tree";
  print "EXECUTING:\n$tline -f '$tfilename'\n\n" if DesignCenter::Config->veryverbose;
  open my $parse, "$tline -f '$tfilename'|"
    or die "Could not run [$tline -f '$tfilename']: $!";

  # Eliminate spurious output
  my $ptree_str = join "\n", grep { !/^(Undeclared|Apparent|No such)/ } <$parse>;
  my $ptree;

  eval { $ptree = DesignCenter::JSON->coder->decode($ptree_str); };

  my @rejects;

  if ($ptree && exists $ptree->{bundles} && ref $ptree->{bundles} eq 'ARRAY') {
    my @bundles = @{$ptree->{bundles}};
    my $bnamespace;
    my $bname;
    my $bname_printable;
    my $bnamespace_printable;

    foreach my $bundle (grep { $_->{'bundle-type'} eq 'agent' } @bundles) {
      print "Looking at agent bundle $bundle->{name}\n"
        if DesignCenter::Config->veryverbose;

      my @args = @{$bundle->{arguments}};
      ($bnamespace, $bname) = split ':', $bundle->{name};
      unless ($bname)
        {
          $bname = $bnamespace;
          undef $bnamespace;
        }

      $bnamespace_printable = $bnamespace || 'default';
      $bname_printable = "$bname (namespace=$bnamespace_printable)";
      print "Found bundle $bname_printable with args @args\n" if DesignCenter::Config->verbose;

      # extract the variables.  start with a context called 'activated' by default
      my %vars = (
                  activated => { type => 'CONTEXT', default => 'any' },
                 );

      my %returns;

      foreach my $ptype (@{$bundle->{'promise-types'}}) {
        print "Looking at promise type $ptype->{name}\n"
          if DesignCenter::Config->veryverbose;

        next unless $ptype->{name} eq 'meta';
        foreach my $class (@{$ptype->{'classes'}}) {
          print "Looking at class $class->{name}\n"
            if DesignCenter::Config->veryverbose;

          if ($class->{name} eq 'any') {
            foreach my $promise (@{$class->{promises}}) {
              print "Looking at 'any' meta promiser $promise->{promiser}\n"
                if DesignCenter::Config->veryverbose;

              if ($promise->{promiser} =~ m/^vars\[([^]]+)\]\[(type|default)\]$/) {
                my ($var, $spec) = ($1, $2);

                print "Found promiser for var $var: $spec\n"
                  if DesignCenter::Config->veryverbose;

                if (exists $promise->{attributes}->[0]->{lval} &&
                    exists $promise->{attributes}->[0]->{rval}) {
                  my $lval = $promise->{attributes}->[0]->{lval};
                  my $rval = $promise->{attributes}->[0]->{rval};
                  if ('string' eq $lval) {
                    if ('string' eq $rval->{type}) {
                      $vars{$var}->{$spec} = $rval->{value};
                    } elsif ('function-call' eq $rval->{type}) {
                      foreach my $farg (@{$rval->{arguments}}) {
                        next if $farg->{type} eq 'string';
                        push @rejects, "Sorry, meta var promise $promise->{promiser} in bundle $bname_printable has a function call for a default with non-string argument $farg->{value}";
                      }

                      unless (scalar @rejects)
                        {
                          $vars{$var}->{$spec} = {
                                                  function =>  $rval->{name},
                                                  args => [map { $_->{value} } @{$rval->{arguments}}],
                                                 };
                        }
                    } else {
                      push @rejects, "Sorry, meta var promise $promise->{promiser} in bundle $bname_printable has invalid value type $rval->{type}";
                    }
                  } else {
                    push @rejects, "Sorry, meta var promise $promise->{promiser} in bundle $bname_printable has invalid type $lval";
                  }
                } else {
                  push @rejects, "Sorry, promiser $promise->{promiser} in bundle $bname_printable is invalid";
                }
              } elsif ($promise->{promiser} =~ m/^returns\[([^]]+)\]$/) {
                my ($var) = ($1);

                print "Found promiser for returns $var\n"
                  if DesignCenter::Config->veryverbose;

                if (exists $promise->{attributes}->[0]->{lval} &&
                    exists $promise->{attributes}->[0]->{rval}) {
                  my $lval = $promise->{attributes}->[0]->{lval};
                  my $rval = $promise->{attributes}->[0]->{rval};
                  if ('string' eq $lval) {
                    if ('string' eq $rval->{type}) {
                      $returns{$var} = $rval->{value};
                    } else {
                      push @rejects, "Sorry, meta returns promise $promise->{promiser} in bundle $bname_printable has invalid value type $rval->{type}";
                    }
                  } else {
                    push @rejects, "Sorry, meta var promise $promise->{promiser} in bundle $bname_printable has invalid type $lval";
                  }
                } else {
                  push @rejects, "Sorry, promiser $promise->{promiser} in bundle $bname_printable is invalid";
                }
              }
            }                   # foreach promise
          } else {
            Util::warning "Sorry, we can't parse conditional ($class->{name}) meta promises in $bname_printable\n"
                if DesignCenter::Config->verbose;
          }
        }
      }

      foreach my $var (sort keys %vars) {
        next if exists $vars{$var}->{type};
        push @rejects, "In $bname_printable, the meta definition for variable $var does not have a type (e.g. \"vars[umask][type]\" string => \"OCTAL\")";
      }

      foreach my $arg (@args) {
        if (exists $vars{$arg}) {
          my $definition = {
                            name => $arg,
                            type => (exists $vars{$arg}->{type} ? $vars{$arg}->{type} : '???'),
                            passed => 1,
                           };

          $definition->{default} = $vars{$arg}->{default}
            if exists $vars{$arg}->{default};

          push @{$meta->{varlist}}, $definition;
          delete $vars{$arg};
        } else {
          push @rejects, "$bname_printable has argument $arg which is not defined as a meta promise (e.g. \"vars[umask][type]\" string => \"OCTAL\")";
        }
      }

      foreach my $var (sort keys %vars) {
        if ($vars{$var}->{type} eq 'CONTEXT') {
          my $definition = {
                            name => $var,
                            type => $vars{$var}->{type},
                            passed => 0,
                           };

          $definition->{default} = $vars{$var}->{default}
            if exists $vars{$var}->{default};

          push @{$meta->{varlist}}, $definition;
          delete $vars{$var};
        } else {
          push @rejects, "$bname_printable has a meta vars promise that does not correspond to a bundle argument";
        }
      }

      $meta->{returns} = \%returns;
      $meta->{bundle_name} = $bname;
      $meta->{bundle_namespace} = $bnamespace;
      last;                     # only try the first bundle!
    }

    unless ($bname)
      {
        push @rejects, "Couldn't find a usable bundle in $maincf_filename";
      }
  } else                        # $ptree is not valid
    {
      if (length $ptree_str > 500) {
        $ptree_str = substr($ptree_str, 0, 500);
      }

      push @rejects, "Could not parse $maincf_filename with [$tline -f '$tfilename']: $ptree_str";
    }

  my $formatted_meta = DesignCenter::JSON::pretty_print_json($meta);
  print "$maincf_filename bundle parse gave us [$formatted_meta]\n" if DesignCenter::Config->veryverbose;

  if (scalar @rejects) {
    foreach (@rejects) {
      Util::warning "$_\n" unless DesignCenter::Config->quiet;
    }

    return undef;
  }

  return $meta;
}

sub configure_with_file
  {
    my $self = shift;
    my $pfile = shift;
    my $sketch = $self->name;

    print "Loading activation params from $pfile\n" unless DesignCenter::Config->quiet;
    my $aparams_all = DesignCenter::JSON::load($pfile);

    do { Util::error "Could not load activation params from $pfile\n"; return }
        unless ref $aparams_all eq 'HASH';

    do { Util::error "Could not find activation params for $sketch in $pfile\n"; return }
        unless exists $aparams_all->{$sketch};

    my $aparams = $aparams_all->{$sketch};

    foreach my $extra (sort keys %{DesignCenter::Config->params}) {
      $aparams->{$extra} = DesignCenter::Config->params->{$extra};
      printf("Overriding aparams %s from the command line, value %s\n",
             $extra, DesignCenter::Config->params->{$extra})
        if DesignCenter::Config->verbose;
    }

    my $installed = 0;
    foreach my $repo (@{DesignCenter::Config->repolist}) {
      my $contents = CFSketch::repo_get_contents($repo);
      if (exists $contents->{$sketch}) {
        my $data = $contents->{$sketch};
        my $if = $data->{interface};

        my $entry_point = verify_entry_point($sketch, $data);

        if ($entry_point) {
          my $varlist = $entry_point->{varlist};
          my $fails;
          foreach my $var (@$varlist) {
            if (exists $aparams->{$var->{name}}) {
            } else {
              if (exists $var->{default}) {
                if ($var->{type} =~ m/^LIST\(.+\)$/s &&
                    ref $var->{default} eq '' &&
                    $var->{default} =~ m/^KVKEYS\((\w+)\)$/) {
                  my $default;
                  foreach my $var2 (@$varlist) {
                    my $name2 = $var2->{name};
                    if ($name2 eq $1) {
                      if (exists $aparams->{$name2} &&
                          ref $aparams->{$name2} eq 'HASH') {
                        $default = $var->{default} = [ keys %{$aparams->{$name2}} ];
                      } else {
                        Util::error "$var->{name} default KVKEYS($1) failed because $name2 did not have a valid value\n";
                        return;
                      }
                    }
                  }

                  do { Util::error "$var->{name} KVKEYS default $var->{default} failed because a matching variable could not be found\n"; return; }
                      unless $default;
                } elsif ($var->{type} =~ m/^ARRAY\(/ &&
                         ref $var->{default} eq '') {
                  my $decoded;
                  eval { $decoded = DesignCenter::JSON->coder->decode($var->{default}); };
                  do { Util::error "Given default '$var->{default}' for ARRAY variable was invalid JSON"; return; }
                      unless ref $decoded eq 'HASH';

                  print "Decoding default JSON data '$var->{default}' for $var->{name}\n"
                    if DesignCenter::Config->veryverbose;

                  $var->{default} = $decoded;
                }

                $aparams->{$var->{name}} = $var->{default};
              } else {
                do { Util::error "Can't configure $sketch: its interface requires variable '$var->{name}' and no default is available\n"; return; }
                }
            }

            if (ref $aparams->{$var->{name}} eq 'HASH' &&
                exists $aparams->{$var->{name}}->{bypass_validation}) {
             $aparams->{$var->{name}} = $aparams->{$var->{name}}->{bypass_validation};
             $var->{bypass_validation} = 1;
            }

            # for contexts, translate booleans to any or !any
            if (DesignCenter::JSON::is_json_boolean($aparams->{$var->{name}}) &&
                $var->{type} eq 'CONTEXT') {
              $aparams->{$var->{name}} = $aparams->{$var->{name}} ? 'any' : '!any';
            }

            if (exists $var->{bypass_validation} ||
                validate($aparams->{$var->{name}}, $var->{type})) {
              print "Satisfied by aparams: '$var->{name}'\n" if DesignCenter::Config->verbose;
            } else {
              my $ad = DesignCenter::JSON->coder->encode($aparams->{$var->{name}});
              Util::warning "Can't configure $sketch: '$var->{name}' value $ad fails $var->{type} validation\n";
              $fails++;
            }
          }
          do { Util::error "Validation errors"; return; } if $fails;
        } else {
          Util::error "Can't configure $sketch: missing entry point in $data->{entry_point}";
          return;
          }

        # Install configuration info
        return unless install_config($sketch, $aparams);

        $installed = 1;
        last;
      }
    }

    do { Util::error "Could not configure sketch $sketch, it was not in the given list of repositories [@{DesignCenter::Config->repolist}]\n"; return; }
        unless $installed;
  }

sub install_config {
  my $sketch = shift;
  my $aparams = shift;
  # activation successful, now install it
  my $activations = DesignCenter::JSON::load(DesignCenter::Config->actfile, 1);

  foreach my $check (@{$activations->{$sketch}}) {
    my $p = DesignCenter::JSON->canonical_coder->encode($check);
    my $q = DesignCenter::JSON->canonical_coder->encode($aparams);
    if ($p eq $q) {
      if (DesignCenter::Config->force) {
        Util::warning "Activating duplicate parameters [$q] because of --force.\n"
            unless DesignCenter::Config->quiet;
      } else {
        Util::error "Can't configure: $sketch has already been configured with this set of parameters.\n";
        return undef;
      }
    }
  }

  push @{$activations->{$sketch}}, $aparams;
  my $activation_id = scalar @{$activations->{$sketch}};

  CFSketch::maybe_ensure_dir(dirname(DesignCenter::Config->actfile));
  CFSketch::maybe_write_file(DesignCenter::Config->actfile, 'activation', DesignCenter::JSON->coder->encode($activations));
  Util::message("Configured: $sketch #$activation_id\n") unless DesignCenter::Config->quiet;

  return 1;
}

sub validate
  {
    my $value = shift;
    my @validation_types = @_;

    # null values are never valid
    return undef unless defined $value;

    if (ref $value eq 'HASH' &&
        exists $value->{bycontext} &&
        ref $value->{bycontext} eq 'HASH') {
      my $ret = 1;
      foreach my $context (sort keys %{$value->{bycontext}}) {
        my $ret2k = validate($context, "CONTEXT");
        Util::warning("Validation failed in bycontext, context key $context\n")
            unless $ret2k;
        my $val2 = $value->{bycontext}->{$context};
        my $ret2v = validate($val2, @validation_types);

        Util::warning("Validation failed in bycontext VALUE '$val2', key $context, validation types [@validation_types]\n")
            unless $ret2v;

        $ret &&= $ret2k && $ret2v;
      }

      return $ret;
    }

    if (ref $value eq 'ARRAY') {
      my $vt = $validation_types[0];
      return undef unless $vt;
      return undef unless $vt =~ m/^LIST\((.+)\)$/s;

      my $subtype = $1;
      my $ret = 1;
      foreach my $subval (@$value) {
        my $ret2 = validate($subval, $subtype);
        Util::warning("LIST validation failed in bycontext, VALUE '$subval'\n")
            unless $ret2;

        $ret &&= $ret2;
      }

      return $ret;
    }

    my $good = 0;
    foreach my $vtype (@validation_types) {
      if ($vtype =~ m/^(KV)?ARRAY\(\n*(.*)\n*\s*\)/s) {
        if (ref $value ne 'HASH') {
          Util::warning("Sorry, but ARRAY validation was requested on a non-array value '$value'.  We'll fail the validation.\n");
          return undef;
        }

        my $kv = $1;
        my %contents = ($2 =~ m/^([^:\s]+)\s*:\s*(.+?)$/mg);

        $good = 1;

        my $kv_key;

        if ($kv) {
          $kv_key = '_key';
          foreach my $k (sort keys %$value) {
            my $goodk = validate($k, $contents{$kv_key});
            Util::warning("Sorry, but KVARRAY validation failed for K '$k' with type '$contents{$kv_key}'.  We'll fail the validation.\n")
                unless $goodk;
            $good &&= $goodk;
          }
        }

        foreach my $process_key ($kv ? (sort keys %$value) : (1)) {
          my $process_value = $kv ? $value->{$process_key} : $value;

          if (ref $process_value ne 'HASH') # this check is necessary only when $kv
            {
              Util::warning("Sorry, but KVARRAY validation was requested on a non-array entry value '$process_value'.  We'll fail the validation.\n");
              return undef;
            }

          foreach my $key (sort keys %contents) {
            next if (defined $kv_key && $key eq $kv_key);

            my $check_value = $process_value->{$key};

            my $subtype = $contents{$key};
            my $required = 0;

            if ($subtype =~ m/(.+):\s*required/) {
              $subtype = $1;
              $required = 1;
            } elsif ($subtype =~ m/(.+):\s*default=(.*)/) {
              $subtype = $1;
              $process_value->{$key} = $2
                unless exists $process_value->{$key};
            }

            if ($required || defined $check_value) {
              my $good2 = validate($check_value, $subtype);

              unless ($good2)
                {
                  Util::warning("ARRAY validation: value '$check_value', subtype '$subtype', subkey '$process_key'.  We'll fail the validation.\n")
                      if DesignCenter::Config->verbose;
                }

              $good &&= $good2;
            }
          }
        }
      } elsif ($vtype eq 'PATH') {
        $good ||= $value =~ m,^/,; # fails on Win32
      } elsif ($vtype eq 'CONTEXT') {
        $good ||= $value =~ m/^[\w!.|&()]+$/;
      } elsif ($vtype eq 'OCTAL') {
        $good ||= $value =~ m/^[0-7]+$/;
      } elsif ($vtype eq 'DIGITS') {
        $good ||= $value =~ m/^[0-9]+$/;
      } elsif ($vtype eq 'IPv4_ADDRESS') {
        $good ||= ($value =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)+$/ &&
                   $1 >= 0 && $1 <= 255 &&
                   $2 >= 0 && $2 <= 255 &&
                   $3 >= 0 && $3 <= 255 &&
                   $4 >= 0 && $4 <= 255);
      } elsif ($vtype eq 'BOOLEAN') {
        $good ||= $value =~ m/^(true|false|on|off|1|0)$/i;
      } elsif ($vtype eq 'NON_EMPTY_STRING') {
        $good ||= length $value;
      } elsif ($vtype eq 'CONTEXT_NAME') {
        $good ||= $value !~ m/\W/;
      } elsif ($vtype eq 'STRING') {
        $good ||= defined $value;
      } elsif ($vtype eq 'HTTP_URL') {
        $good ||= $value =~ m,^(git|https?)://.+,; # this is not a good URL regex
      } elsif ($vtype eq 'FILE_URL') {
        $good ||= $value =~ m,^(file):///.+,; # this is not a good URL regex
      } elsif ($vtype eq 'FTP_URL') {
        $good ||= $value =~ m,^(ftp)://.+,; # this is not a good URL regex
      } elsif ($vtype =~  m/\|/) {
        $good = 0;
        foreach my $subtype (split('\|',$vtype)) {
          my $good2 = validate($value, $subtype);
          $good ||= $good2;
        }
      } elsif ($vtype =~ m/^=(.+)/) {
        $good ||= $value eq $1;
      } else {
        Util::warning("Sorry, but an unknown validation type $vtype was requested.  We'll fail the validation, too.\n");
        return undef;
      }

      return 1 if $good;
    }

    return 0;
  }

1;
