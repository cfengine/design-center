package DCAPI::Sketch;

use strict;
use warnings;

use DCAPI::Terms;

use Util;
use Mo qw/default build builder is required option/;

use constant MEMBERS => qw/entry_point interface manifest metadata api namespace/;
use constant META_MEMBERS => qw/name version description license tags depends/;

has dcapi        => ( is => 'ro', required => 1 );
has repo         => ( is => 'ro', required => 1 );
has desc         => ( is => 'ro', required => 1 );
has describe     => ( is => 'rw' );
has location     => ( is => 'ro', required => 1 );
has rel_location => ( is => 'ro', required => 1 );
has verify_files => ( is => 'ro', required => 1 );

# sketch-specific properties
has api         => ( is => 'rw' );
has namespace   => ( is => 'rw' );
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
             $self->desc()||'')
  unless defined $config;

 $self->describe($config);

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
   elsif ($m eq 'namespace')
   {
    # it's OK to have a null namespace
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

 if ($self->verify_files())
 {
  my $manifest = $self->manifest();
  my $name = $self->name();

  foreach my $f (sort keys %$manifest)
  {
   my $file = sprintf("%s/%s", $self->location(), $f);
   die "Sketch $name is missing manifest file $file" unless -f $file;
  }
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

sub get_inputs
{
 my $self = shift;
 my $relocate = shift;
 my $recurse = shift;

 my @inputs;
 if ($recurse)
 {
  my ($depcheck, @dep_warnings) = $self->resolve_dependencies(install => 0);
  if ($depcheck)
  {
   foreach my $dep (keys %$depcheck)
   {
    my $sketch = $self->dcapi()->describe($dep, undef, 1);

    if ($sketch)
    {
     # we decrement the recurse to avoid circular dependencies
     push @inputs, $sketch->get_inputs($relocate, $recurse-1);
    }
    else
    {
     $self->dcapi()->log("Sketch %s could not find dependency %s",
                         $self->name(),
                         $dep);
    }
   }
  }
 }

 my $i = 'ARRAY' eq ref $self->interface() ? $self->interface() : [$self->interface()];
 my $location = $relocate ? "$relocate/" . $self->rel_location() : $self->location();
 push @inputs, map { "$location/$_" } @$i;

 return @inputs;
}

sub resolve_dependencies
{
 my $self = shift @_;
 my %options = @_;

 my %ret;
 my %deps;
 %deps = %{$self->depends()} if ref $self->depends() eq 'HASH';
 my $name = $self->name();

 foreach my $dep (sort keys %deps)
 {
  $self->dcapi()->log2("Checking sketch $name dependency %s", $dep);
  if ($dep eq 'os')
  {
   $self->dcapi()->log2("Ignoring sketch $name OS dependency %s", $dep);
  }
  elsif ($dep eq 'cfengine')
  {
   if (exists $deps{$dep}->{version})
   {
    my $v = $deps{$dep}->{version};
    if ($self->dcapi()->is_ok_cfengine_version($v))
    {
     $self->dcapi()->log3("CFEngine version requirement of sketch $name OK: %s", $v);
    }
    else
    {
     $self->dcapi()->log2("CFEngine version requirement of sketch $name not OK: %s", $v);
     return (undef, "CFEngine version below required $v for sketch $name");
    }
   }
  }
  else                             # anything else is a sketch name...
  {
   my %install_request = ( sketch => $dep, target => $options{target} );
   my @criteria = (["name", "equals", $dep]);
   if (exists $deps{$dep}->{version})
   {
    push @criteria, ["version", ">=", $deps{$dep}->{version}];
   }

   my $list = $self->dcapi()->list(\@criteria, { flatten => 1 });
   if (scalar @$list < 1)
   {
    if ($options{install})
    {
    # try to install the dependency
     my $search = $self->dcapi()->search(\@criteria);
     my $installed = 0;
     foreach my $srepo (sort keys %$search)
     {
      $install_request{source} = $srepo;
      $self->dcapi()->log("Trying to install dependency $dep for $name: %s",
                          \%install_request);
      my ($install_result, @install_warnings) = $self->dcapi()->install([\%install_request]);
      my $check = Util::hashref_search($install_result, $options{target}, $dep);
      if ($check)
      {
       $installed = $install_result;
      }
      else
      {
       push @{$self->dcapi()->warnings()->{$srepo}}, @install_warnings;
      }
     }

     return (undef, "Could not install dependency $dep")
      unless $installed;
    }
    else
    {
     $self->dcapi()->log4("Sketch $name is missing dependency $dep");
    }
   }
   else
   {
    # put the first dependency found in the return
    $ret{$dep} = $list->[0];
   }
  }
 }

 return \%ret;
}

1;
