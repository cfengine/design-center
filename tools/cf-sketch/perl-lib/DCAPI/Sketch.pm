package DCAPI::Sketch;

use strict;
use warnings;

use Util;
use Mo qw/default build builder is required option/;

use constant MEMBERS => qw/entry_point interface manifest metadata/;

use constant META_MEMBERS => qw/name version description license tags depends/;

has api  => ( is => 'ro', required => 1 );
has repo => ( is => 'ro', required => 1 );
has desc => ( is => 'ro', required => 1 );
has location => ( is => 'ro', required => 1 );

# sketch-specific properties
has name        => ( is => 'rw' );
has version     => ( is => 'rw' );
has entry_point => ( is => 'rw' );
has description => ( is => 'rw' );
has license     => ( is => 'rw' );
has entry_point => ( is => 'rw' );
has library     => ( is => 'rw', default => sub { 0 } );

has interface   => ( is => 'rw', default => sub { [] } );
has tags        => ( is => 'rw', default => sub { [] } );

has manifest    => ( is => 'rw', default => sub { {} } );
has metadata    => ( is => 'rw', default => sub { {} } );
has depends     => ( is => 'rw', default => sub { {} } );

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

 foreach my $mm (META_MEMBERS())
 {
  my $v = Util::hashref_search($metadata, $mm);
  unless (defined $v)
  {
   die sprintf("Sketch in location %s is missing required metadata: %s\n",
               $self->location(),
               $mm);
  }

  $self->$mm($v);
 }
}

sub data_dump
{
 my $self = shift;

 return {
         map { $_ => $self->$_ } MEMBERS()
        };
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
