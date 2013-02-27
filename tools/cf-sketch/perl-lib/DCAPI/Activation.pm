package DCAPI::Activation;

use strict;
use warnings;

use Mo qw/default build builder is required option/;

has api => ( is => 'ro', required => 1 );

has sketch => ( is => 'ro', required => 1 );
has runenv => ( is => 'ro', required => 1 );
has bundle => ( is => 'ro', required => 1 );
has params => ( is => 'ro', required => 1 );

sub make_activation
{
 my $api    = shift;
 my $sketch = shift;
 my $spec   = shift;

  if (ref $spec ne 'HASH')
  {
   return (undef, "Invalid activate spec under $sketch");
  }

  my $env = $spec->{env} || '--environment not given (NULL)--';

  unless (exists $api->environments()->{$env})
  {
   return (undef, "Invalid activation environment '$env'");
  }

  my $found;
  my @repos = grep
  {
   defined $spec->{repo} ? $spec->{repo} eq $_->location() : 1
  } map { $api->load_repo($_) } @{$api->repos()};

  foreach my $repo (@repos)
  {
   $found = $repo->find_sketch($sketch);
   last if $found;
  }

  return (undef, sprintf("Could not find sketch $sketch in [%s]",
                        join(' ', map { $_->location() } @repos)))
   unless $found;

  my $params = $spec->{params} || "--no valid params array found--";
  if (ref $params ne 'ARRAY')
  {
   return (undef, "Invalid activation params, must be an array");
  }

  unless (scalar @$params)
  {
   return (undef, "Activation params can't be an empty array");
  }

  my %params;
  foreach (@$params)
  {
   return (undef, "The activation params '$_' have not been defined")
    unless exists $api->definitions()->{$_};

   return (undef, "The activation params '$_' do not apply to sketch $sketch")
    unless exists $api->definitions()->{$_}->{$sketch};

   $params{$_} = $api->definitions()->{$_}->{$sketch};
  }

 $api->log3("Verified sketch %s activation: run environment %s and params %s",
             $sketch, $env, $params);

 $api->log4("Checking sketch %s: API %s versus extracted parameters %s",
             $sketch,
             $found->api(),
             \%params);

 my @bundles_to_check = sort keys %{$found->api()};

 # look at the specific bundle if requested
 if (exists $spec->{bundle} &&
     defined $spec->{bundle})
 {
  @bundles_to_check = grep { $_ eq $spec->{bundle}} @bundles_to_check;
 }

 my $bundle;
 my @params;
 foreach my $b (@bundles_to_check)
 {
  my $sketch_api = $found->api()->{$b};

  my $params_ok = 1;
  foreach my $p (@$sketch_api)
  {
   $api->log5("Checking the API of sketch %s: parameter %s", $sketch, $p);
   my $filled = fill_param($api,
                           $p->{name}, $p->{type}, \%params,
                           {
                            runenv => $api->environments()->{$env}
                           });
   unless ($filled)
   {
    $api->log4("The API of sketch %s did not match parameter %s", $sketch, $p);
    $params_ok = 0;
    last;
   }

   $api->log5("The API of sketch %s matched parameter %s", $sketch, $p);
   push @params, $filled;
  }

  $bundle = $b if $params_ok;
 }

 return (undef, "No bundle in the $sketch api matched the given parameters")
  unless $bundle;

 $api->log3("Verified sketch %s entry: filled parameters are %s",
             $sketch, \@params);

 return DCAPI::Activation->new(api => $api,
                               sketch => $found,
                               runenv => $env,
                               bundle => $bundle,
                               params => \@params);
}

sub fill_param
{
 my $api    = shift;
 my $name   = shift;
 my $type   = shift;
 my $params = shift;
 my $extra  = shift;

 if ($type eq 'runenv')
 {
  return {set=>undef, type => $type, name => $name, value => $extra->{runenv}};
 }

 foreach my $pkey (sort keys %$params)
 {
  my $pval = $params->{$pkey};
  # TODO: add more parameter types and validate the value!!!
  if ($type eq 'array' && exists $pval->{$name} && ref $pval->{$name} eq 'HASH')
  {
   return {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
  }
  elsif ($type eq 'string' && exists $pval->{$name} && ref $pval->{$name} eq '')
  {
   return {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
  }
  elsif ($type eq 'boolean' && exists $pval->{$name} && ref $pval->{$name} eq '')
  {
   return {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
  }
  elsif ($type eq 'list' && exists $pval->{$name} && ref $pval->{$name} eq 'ARRAY')
  {
   return {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
  }
 }

 return;
}

1;
