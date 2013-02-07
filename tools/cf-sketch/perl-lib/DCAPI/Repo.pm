package DCAPI::Repo;

use strict;
use warnings;

use File::Spec;
use Mo qw/default build builder is required option/;

use Util;
use DCAPI::Sketch;

use constant SKETCHES_FILE => 'cfsketches.json';

has api       => ( is => 'ro', required => 1 );
has location  => ( is => 'ro', required => 1 );
has local     => ( is => 'rw' );
has writeable => ( is => 'rw', default => sub { 0 });
has inv_file  => ( is => 'rw');
has sketches  => ( is => 'ro', default => sub { [] } );

sub BUILD
{
 my $self = shift;
 $self->local(Util::is_resource_local($self->location()));
 $self->writeable($self->local() && -w $self->location());

 my $inv_file = sprintf("%s/%s", $self->location(), SKETCHES_FILE);

 my ($inv, $reason);

 if ($self->local() && 0 == -s $inv_file)
 {
  $inv = [];
 }
 else
 {
  ($inv, $reason) = $self->api()->load_raw($inv_file);
 }

 die "Can't use repository without a valid inventory file in $inv_file: $reason"
  unless defined $inv;

 foreach my $line (@$inv)
 {
  my ($location, $desc) = split "\t", $line, 2;

  my $abs_location = sprintf("%s/%s", $self->location(), $location);
  eval
  {
   push @{$self->sketches()},
    DCAPI::Sketch->new(location => $abs_location,
                       rel_location => $location,
                       desc => $desc,
                       dcapi => $self->api(),
                       repo => $self);
  };

  if ($@)
  {
   push @{$self->api()->warnings()->{$abs_location}}, $@;
  }

 }

 $self->inv_file($inv_file);
}

sub data_dump
{
 my $self = shift;
 return
 {
  location => $self->location(),
  writeable => $self->writeable(),
  inv_file => $self->inv_file(),
  sketches => [map { $_->data_dump() } @{$self->sketches()}],
 };
}

sub sketches_dump
{
 my $self = shift;
 my @lines =
  sort { $a cmp $b }
  map { sprintf("%s %s", $_->rel_location(), $_->desc()); }
  @{$self->sketches()};

 return @lines;
}

sub list
{
 my $self = shift;
 my $term_data = shift @_;

 return grep { $_->matches($term_data) } @{$self->sketches()};
}

sub find_sketch
{
 my $self = shift;
 my $name = shift || 'nonesuch';

 foreach (@{$self->sketches()})
 {
  return $_ if $name eq $_->name();
 }

 return;
}

sub sketch_api
{
 my $self = shift;
 my $sketches = shift;

 foreach my $sname (keys %$sketches)
 {
  my $s = $self->find_sketch($sname);
  next unless defined $s;
  push @{$sketches->{$s->name()}}, $s->api();
 }

 return $sketches;
}

sub install
{
 my $self = shift @_;
 my $from = shift @_;
 my $sketch = shift @_;

 # 1. copy the sketch files as in the manifest
  my $abs_location = sprintf("%s/%s", $self->location(), $location);
  eval
  {
   push @{$self->sketches()},
    DCAPI::Sketch->new(location => $abs_location,
                       rel_location => $location,
                       desc => $desc,
                       dcapi => $self->api(),
                       repo => $self);
  };

  if ($@)
  {
   push @{$self->api()->warnings()->{$abs_location}}, $@;
  }

 # 2. update cfsketches.json
 die "installer! " . join("\n", $self->sketches_dump());
}

sub equals
{
 my $self = shift;
 my $other = shift @_;

 return (ref $self eq ref $other &&
         $self->location() eq $other->location());
}

1;
