#!/usr/bin/env perl -w
#
# DesignCenter::Sketch
# Representation of a sketch
#
# Diego Zamboni <diego.zamboni@cfengine.com>
# Time-stamp: <2012-10-05 01:05:14 a10022>

package DesignCenter::Sketch;

use Carp;
use Util;
our $AUTOLOAD;                  # it's a package global

# Allowed data fields, for setters/getters
my %fields = (
              name => undef,
              location => undef,
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

1;

