package DCAPI::Sketch;

use strict;
use warnings;

use DCAPI::Terms;

use Util;
use Mo qw/default build builder is required option/;

use constant MEMBERS => qw/entry_point interface manifest metadata api/;
use constant META_MEMBERS => qw/name version description license tags depends/;

has dcapi  => ( is => 'ro', required => 1 );
has repo => ( is => 'ro', required => 1 );
has desc => ( is => 'ro', required => 1 );
has location => ( is => 'ro', required => 1 );

# sketch-specific properties
has api         => ( is => 'rw' );
has entry_point => ( is => 'rw' );
has interface   => ( is => 'rw' );
has library     => ( is => 'rw', default => sub { 0 } );

has manifest    => ( is => 'rw', default => sub { {} } );
has metadata    => ( is => 'rw', default => sub { {} } );

sub BUILD
{
 my $self = shift;

 my ($config, $reason) = $self->dcapi()->load($self->desc());
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

# yeah it's a hack, but better than AUTOLOAD
# define a metadata accessor for each keyword in META_MEMBERS
foreach my $mm ( META_MEMBERS() )
{
 my $method_name = __PACKAGE__ . '::' . $mm;
 no strict 'refs';
 *{$method_name} = sub
 {
  my $self = shift @_;
  if (scalar @_)
  {
   $self->metadata()->{$mm} = shift;
  }

  return $self->metadata()->{$mm};
 };
}

sub data_dump
{
 my $self = shift;
 my $flatten = shift;

 my %ret = (
            map { $_ => $self->$_ } MEMBERS()
           );
 if ($flatten)
 {
  foreach my $mkey (META_MEMBERS())
  {
   $ret{$mkey} = $ret{metadata}->{$mkey}
    if exists $ret{metadata}->{$mkey};
  }
 }

 return \%ret;
}

sub matches
{
 my $self = shift;
 my $term_data = shift;

 my $terms = DCAPI::Terms->new(api => $self->dcapi(),
                               terms => $term_data);

 my $my_data = $self->data_dump(1);     # flatten it
 my $ok = $terms->matches($my_data);

 $self->dcapi()->log_int($ok ? 4:5,
                         "sketch %s %s terms %s",
                         $self->name,
                         $ok ? 'matched' : 'did not match',
                         $term_data);
 return $ok;
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
