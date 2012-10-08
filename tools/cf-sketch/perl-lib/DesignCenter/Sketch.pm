#!/usr/bin/env perl -w
#
# DesignCenter::Sketch
# Representation of a sketch
#
# Diego Zamboni <diego.zamboni@cfengine.com>
# Time-stamp: <2012-10-08 15:59:39 a10022>

package DesignCenter::Sketch;

use Carp;
use Util;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;
use DesignCenter::JSON;
use DesignCenter::Config;

our $AUTOLOAD;                  # it's a package global

# Allowed data fields, for setters/getters
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

  unless (exists $self->{_permitted}->{$name} ) {
    croak "Can't access `$name' field in class $type";
  }

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
      push @messages, "Invalid manifest" unless (exists $json->{manifest} && ref $json->{manifest} eq 'HASH');

      # the metadata must be a hash
      push @messages, "Invalid metadata" unless (exists $json->{metadata} && ref $json->{metadata} eq 'HASH');

      # the interface must be an array
      push @messages, "Invalid interface" unless (exists $json->{interface} && ref $json->{interface} eq 'ARRAY');
    }

  # stage 3: check metadata details
  unless (scalar @messages)
    {
      # need a 'depends' key that points to a hash
      push @messages, "Invalid dependencies structure" unless (exists $json->{metadata}->{depends}  &&
                                                               ref $json->{metadata}->{depends}  eq 'HASH');

      foreach my $scalar (qw/name version license/) {
        push @messages, "Missing or undefined metadata element $scalar" unless $json->{metadata}->{$scalar};
      }

      foreach my $array (qw/authors portfolio/) {
        push @messages, "Missing, invalid, or undefined metadata array $array" unless ($json->{metadata}->{$array} &&
                                                                                       ref $json->{metadata}->{$array} eq 'ARRAY');
      }

      unless (scalar @messages)
        {
          push @messages, "Portfolio metadata can't be empty" unless scalar @{$json->{metadata}->{portfolio}};
        }
    }

  # stage 4: check entry_point and interface
  unless (scalar @messages)
    {
      push @messages, "Missing entry_point" unless exists $json->{entry_point};
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
        push @messages, "interface file $_ not in manifest" unless exists $json->{manifest}->{$_};
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
          $self->verify_entry_point($name, $json)) {
        # note this name will be stringified even if it's not a string
        $self->json_data($json) if $am_object;
        return $json;
      } else {
        Util::color_warn "Could not verify bundle entry point from $name" unless DesignCenter::Config->quiet;
      }
    } else {
      Util::color_warn "Could not load sketch definition from $name: [@{[join '; ', @messages]}]" unless DesignCenter::Config->quiet;
    }

  $self->json_data(undef) if $am_object;
  return undef;
}

sub verify_entry_point {
  my $self = shift;
  my $name = shift;
  my $data = shift;

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
          Util::color_warn "Could not find sketch $name entry point '$maincf_filename'" unless DesignCenter::Config->quiet;
          return 0;
        }

      unless (open($mcf, '<', $maincf_filename) && $mcf)
        {
          Util::color_warn "Could not open $maincf_filename: $!" unless DesignCenter::Config->quiet;
          return 0;
        }
      @mcf = <$mcf>;
      $mcf = join "\n", @mcf; # make sure the whole string is available
    } else {
      $mcf = Util::get_remote($maincf_filename);
      unless ($mcf)
        {
          Util::color_warn "Could not retrieve $maincf_filename: $!" unless DesignCenter::Config->quiet;
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

  # print "PARSING:\n$mcf\n\n" if DesignCenter::Config->veryverbose;

  print $tfh $mcf;
  close $tfh;

  my $pb = CFSketch::cfengine_promises_binary();
  my $tline = "$pb --parse-tree";
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
            Util::color_warn "Sorry, we can't parse conditional ($class->{name}) meta promises in $bname_printable"
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

  print "$maincf_filename bundle parse gave us " . Dumper($meta) if DesignCenter::Config->veryverbose;

  if (scalar @rejects) {
    foreach (@rejects) {
      Util::color_warn $_ unless DesignCenter::Config->quiet;
    }

    return undef;
  }

  return $meta;
}

1;
