package DCAPI::Terms;

use strict;
use warnings;

use Util;

use Mo qw/default build builder is required option/;

has api   => ( is => 'ro', required => 1 );
has terms => ( is => 'rw' );

sub BUILD
{
 my $self = shift;
 my $terms = $self->terms();

 # it's either boolean or a HASH ref
 $self->api()->log5('Building terms with data %s', $terms);
}

sub matches
{
 my $self = shift;
 my $data = shift;
 my $terms = $self->terms();

 $self->api()->log5('Matching terms %s against %s', $terms, $data);
 if (ref $terms eq 'ARRAY')
 {
  foreach my $q (@$terms)
  {
   next unless ref $q eq 'ARRAY';

   my $ok = 0;
   eval
   {
    my ($k, $check, $v) = @$q;
    $k = [$k] unless ref $k eq 'ARRAY';

    if ($check eq 'matches')
    {
     my $datum = Util::hashref_search($data, @$k);
     $self->api()->log4('Term %s checking against %s', $q, $datum);
     if ((!defined $datum && !defined $v) ||
         (defined $datum && defined $v && $datum =~ m/$v/i))
     {
      $ok = [$k, $v];
     }
    }
    else
    {
     $self->api()->log('Invalid term check %s, failing', $check);
    }
   };
   return $ok if $ok;
  }
 }
 else
 {
  $self->api()->log5('Terms %s always match', $terms);
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
