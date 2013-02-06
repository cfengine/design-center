package DCAPI::Terms;

use strict;
use warnings;

use Util;

use Mo qw/default build builder is required option/;

has api   => ( is => 'ro', required => 1 );
has terms => ( is => 'rw', required => 1 );

sub BUILD
{
 my $self = shift;
 my $terms = $self->terms();

 # it's either boolean or a HASH ref
 $self->terms(! ! $terms) if ref $terms ne 'HASH';
}

sub matches
{
 my $self = shift;
 my $data = shift;
 my $terms = $self->terms();

 if (ref $terms eq 'HASH')
 {
  foreach my $k (keys %$terms)
  {
   $k = [$k] if ref $k ne 'ARRAY';
   my $v = $terms->{$k};
   return [$k, $v] if (defined $v && $v eq Util::hashref_search($data, @$k))
  }
 }
 else
 {
  return $terms;
 }

 return; # no match
}

sub equals
{
 my $self = shift;
 my $other = shift @_;

 return (ref $self eq ref $other &&
         $self->api()->encode($self->terms()) eq $self->api()->encode($other->terms()));
}

1;
