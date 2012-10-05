#!/usr/bin/env perl -w
#
# DesignCenter::Repository
# Representation of a repository containing sketches
#
# Diego Zamboni <diego.zamboni@cfengine.com>
# Time-stamp: <2012-10-05 01:12:33 a10022>

package DesignCenter::Repository;

use Carp;
use Util;
use File::Basename;
use DesignCenter::Sketch;
our $AUTOLOAD;                  # it's a package global

# Allowed data fields, for setters/getters
my %fields = (
              # Internal fields
              _basedir => undef,
              _local => undef,
              _config => undef,
              _lines => undef,
              # Default repository - base location where the cfsketches file can be found
              uri => undef,
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
  my $config = shift;
  my $uri = shift;
  # Data initialization
  my $self  = {
               _permitted => \%fields,
               %fields,
              };
  # Get the URI from the argument if provided (else see default value above)
  $self->{uri} = $uri || $config->installsource || $self->{uri};
  die "Need the repository URI for creation" unless $self->{uri};
  $self->{_config} = $config;

  # Convert myself into an object
  bless($self, $class);

  # Compute some other basic characteristics
  $self->_setup;

  return $self;
}

sub _setup {
  my $self=shift;
  $self->_basedir(dirname($self->uri));
  $self->_local(Util::is_resource_local($self->_basedir));
}

sub list
  {
    my $self = shift;
    my @terms = @_;
    my $source = $self->{_config}->installsource;
    my $base_dir = $self->_basedir;
    my $search = $self->search_internal([]);
    my $local_dir = $self->_local;
    my @result = ();

  SKETCH:
    foreach my $sketch (sort keys %{$search->{known}}) {
      my $dir = $local_dir ? File::Spec->catdir($base_dir, $search->{known}->{$sketch}) : "$base_dir/$search->{known}->{$sketch}";
      foreach my $term (@terms) {
        if ($sketch =~ m/$term/i || $dir =~ m/$term/i) {
          push @result, DesignCenter::Sketch->new(name => $sketch,
                                                  location => $dir,
                                                 );
          next SKETCH;
        }
      }
    }
    return @result;
  }

sub search_internal
  {
    my $self = shift;
    my $source = $self->uri;
    my $sketches = shift @_;

    my %known;
    my %todo;
    my $local_dir = $self->_local;

    if ($local_dir) {
      Util::color_die "cf-sketch inventory source $source must be a file"
          unless -f $source;

      open(my $invf, '<', $source)
        or Util::color_die "Could not open cf-sketch inventory file $source: $!";

      while (<$invf>) {
        my $line = $_;

        my ($dir, $sketch, $etc) = (split ' ', $line, 3);
        $known{$sketch} = $dir;

        foreach my $s (@$sketches) {
          next unless ($sketch eq $s || $dir eq $s);
          $todo{$sketch} = $dir;
        }
      }
    } else {
      my @lines = @{$self->_lines};
      unless (@lines) {
        my $invd = Util::get_remote($source)
          or Util::color_die "Unable to retrieve $source : $!\n";

        @lines = split "\n", $invd;
        $self->_lines(\@lines);
      }
      foreach my $line (@lines) {
        my ($dir, $sketch, $etc) = (split ' ', $line, 3);
        $known{$sketch} = $dir;

        foreach my $s (@$sketches) {
          next unless ($sketch eq $s || $dir eq $s);
          $todo{$sketch} = $dir;
        }
      }
    }

    return { known => \%known, todo => \%todo };
  }

