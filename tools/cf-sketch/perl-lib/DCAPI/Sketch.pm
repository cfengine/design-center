package DCAPI::Sketch;

use strict;
use warnings;

use DCAPI::Terms;

use Util;
use Mo qw/default build builder is required option/;

use constant MEMBERS => qw/entry_point interface manifest metadata/;
use constant META_MEMBERS => qw/name version description license tags depends/;

has api  => ( is => 'ro', required => 1 );
has repo => ( is => 'ro', required => 1 );
has desc => ( is => 'ro', required => 1 );
has location => ( is => 'ro', required => 1 );

# sketch-specific properties
has entry_point => ( is => 'rw' );
has interface   => ( is => 'rw' );
has library     => ( is => 'rw', default => sub { 0 } );

has manifest    => ( is => 'rw', default => sub { {} } );
has metadata    => ( is => 'rw', default => sub { {} } );

sub BUILD
{
 my $self = shift;

 my ($config, $reason) = $self->api()->load($self->desc());
 die sprintf("Sketch in location %s could not initialize ($reason) from data %s\n",
             $self->location(),
             $self->desc())
  unless defined $config;

 my $metadata = Util::hashref_search($config, 'metadata');

 foreach my $m (MEMBERS())
 {
  my $v = Util::hashref_search($config, $m);
  unless (defined $v)
  {
   if ($m eq 'entry_point')
   {
    $self->library(1);
   }
   else
   {
    die sprintf("Sketch in location %s is missing required attribute: %s\n",
                $self->location(),
                $m);
   }
  }

  $self->$m($v);
 }
}

# yeah it's a hack
foreach my $mm (META_MEMBERS())
{
 eval sprintf('sub %s { $self = shift @_; if (scalar @_) { $self->metadata()->{%s} = shift; } return $self->metadata()->{%s}',
              $mm, $mm, $mm);
}

sub data_dump
{
 my $self = shift;

 return {
         map { $_ => $self->$_ } MEMBERS()
        };
}

sub matches
{
 my $self = shift;
 my $term_data = shift;

 my $terms = DCAPI::Terms->new(api => $self->api(),
                               terms => $term_data);

 return $terms->matches($self->data_dump());
}

sub equals
{
 my $self = shift;
 my $other = shift @_;

 return (ref $self eq ref $other &&
         $self->name() eq $other->name() &&
         $self->version() eq $other->version());
}

1;
