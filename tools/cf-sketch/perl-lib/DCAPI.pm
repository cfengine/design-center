package DCAPI;

use strict;
use warnings;

use JSON;
use File::Which;

use DCAPI::Repo;

use constant API_VERSION => '0.0.1';
use constant CODER => JSON->new()->relaxed()->utf8()->allow_nonref();
use constant CAN_CODER => JSON->new()->canonical()->utf8()->allow_nonref();

use Mo qw/build default builder coerce is required/;

# has name2 => ( builder => 'name_builder' );
# has name4 => ( required => 1 );

has version => ( is => 'ro', default => sub { API_VERSION } );

has config => ( );

has curl => ( is => 'ro', default => sub { which('curl') } );
has repos => ( is => 'ro', default => sub { [] } );
has warnings => ( is => 'ro', default => sub { {} } );

has coder =>
 (
  is => 'ro',
  default => sub { CODER },
 );

has canonical_coder =>
 (
  is => 'ro',
  default => sub { CAN_CODER },
 );

sub set_config
{
 my $self = shift @_;
 my $file = shift @_;

 $self->config($self->load($file));

 foreach my $repo (@{Util::hashref_search($self->config(), qw/repolist/) || []})
 {
  eval
  {
   push @{$self->repos()}, DCAPI::Repo->new(location => $repo);
  };

  if ($@)
  {
   push @{$self->warnings()->{$repo}}, $@;
  }
 }

 return (1, $self->warnings());
}

sub log { shift; print STDERR @_; };

sub decode { shift; CODER->decode(@_) };
sub encode { shift; CODER->encode(@_) };
sub cencode { shift; CAN_CODER->encode(@_) };

sub curl_GET { shift->curl('GET', @_) };

sub curl
{
 my $self = shift @_;
 my $mode = shift @_;
 my $url = shift @_;

 my $curl = $self->curl();

 my $run = <<EOHIPPUS;
$curl -s $mode $url |
EOHIPPUS

 $self->log("Running: $run\n");

 open my $c, $run or return (undef, "Could not run command [$run]: $!");

 return ([<$c>], undef);
};

sub load
{
 my $self = shift @_;
 my $f = shift @_;

 my @j;

 my $try_eval;
 eval
 {
  $try_eval = $self->decode($f);
 };

 if ($try_eval) # detect inline content, must be proper JSON
 {
  return ($try_eval);
 }
 elsif (Util::is_resource_local($f))
 {
  my $j;
  unless (open($j, '<', $f) && $j)
  {
   return (undef, "Could not inspect $f: $!");
  }

  @j = <$j>;
 }
 else
 {
  my ($j, $error) = $self->curl_GET($f);

  defined $error and return (undef, $error);
  defined $j or return (undef, "Unable to retrieve $f");

  @j = @$j;
 }

 if (scalar @j)
 {
  chomp @j;
  s/\n//g foreach @j;
  s/^\s*(#|\/\/).*//g foreach @j;

  my $ret = $self->decode(join '', @j);

  return ($ret);
 }

 return (undef, "No data was loaded from $f");
}

sub ok
{
 my $self = shift;
 print $self->encode($self->make_ok(@_)), "\n";
}

sub exit_error
{
 shift->error(@_);
 exit 0;
}

sub error
{
 my $self = shift;
 print $self->encode($self->make_error(@_)), "\n";
}

sub make_ok
{
 my $self = shift;
 my $ok = shift;
 $ok->{success} = JSON::true;
 $ok->{errors} ||= [];
 $ok->{warnings} ||= [];
 $ok->{log} ||= [];
 return { api_ok => $ok };
}

sub make_not_ok
{
 my $self = shift;
 my $nok = shift;
 $nok->{success} = JSON::false;
 $nok->{errors} ||= shift @_;
 $nok->{warnings} ||= shift @_;
 $nok->{log} ||= shift @_;
 return { api_not_ok => $nok };
}

sub make_error
{
 my $self = shift;
 return { api_error => [@_] };
}

sub data_dump
{
 return shift;
}

1;
