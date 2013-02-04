package DCAPI::Repo;

use strict;
use warnings;

use File::Spec;
use Mo qw/default builder is required option/;

use Util;

use constant SKETCH_DEF_FILE => 'sketch.json';
use constant SKETCHES_FILE => 'cfsketches.json';

has location  => ( is => 'ro', required => 1 );
has local     => ( is => 'ro', option => 1 );
has writeable => ( is => 'ro', option => 1 , default => sub { 0 });
has inv_file  => ( is => 'ro');
has sketches  => ( is => 'ro', default => sub { [] } );

sub BUILD
{
 my $self = shift;
 $self
  ->local(Util::is_resource_local($self->location()))
  ->writeable($self->read_local() && -w $self->location());

 my $inv_file = sprintf("%s/%s", $self->location(), SKETCHES_FILE);

 my ($inv, $reason) = load($inv_file);

 die "Can't use repository without a valid inventory file in $inv_file: $reason"
  unless defined $inv;
}
