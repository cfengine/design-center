#!/usr/bin/perl

BEGIN
{
 if (-l $0)
 {
  require FindBin;
  $0 = readlink $0;
  FindBin->again();
 }
}

use FindBin;
use lib "$FindBin::Bin/../lib/cf-sketch", "$FindBin::Bin/../lib/cf-sketch/File-Which-1.09/lib", "$FindBin::Bin/../lib/cf-sketch/JSON-2.53/lib", "$FindBin::Bin/perl-lib", "$FindBin::Bin/perl-lib/File-Which-1.09/lib", "$FindBin::Bin/perl-lib/JSON-2.53/lib";

use warnings;
use strict;
use JSON;
use File::Which;

use Util;
use constant SKETCH_DEF_FILE => 'sketch.json';

$| = 1;                         # autoflush

my $coder = JSON->new()->relaxed()->utf8()->allow_nonref();
# for storing JSON data so it's directly comparable
my $canonical_coder = JSON->new()->canonical()->utf8()->allow_nonref();
my $curl = which('curl');

unless ($curl)
{
 api_exit_error("$0: could not locate `curl' executable in $ENV{PATH}");
}

my $config_file = shift @ARGV;

unless ($config_file)
{
 api_exit_error("Syntax: $0 CONFIG_FILE");
}

my ($config, @errors) = load($config_file);

unless ($config)
{
 api_exit_error("$0 could not load $config_file");
}

print api_ok({ data => { config => $config } });

sub api_ok
{
  print $coder->encode(make_ok(@_)), "\n";
}

sub api_exit_error
{
 api_error(@_);
 exit 0;
}

sub api_error
{
  print $coder->encode(make_error(@_)), "\n";
}

sub make_ok
{
 my $ok = shift;
 $ok->{success} = JSON::true;
 $ok->{errors} = [];
 $ok->{warnings} = [];
 $ok->{log} = [];
 return { api_ok => $ok };
}

sub make_not_ok
{
 my $nok = shift;
 $nok->{success} = JSON::false;
 $nok->{errors} = shift @_;
 $nok->{warnings} = shift @_;
 $nok->{log} = shift @_;
 return { api_not_ok => $nok };
}

sub make_error
{
 return { api_error => [@_] };
}

sub load
{
 my $f = shift @_;

 my @j;

 my $try_eval;
 eval
 {
  $try_eval = $coder->decode($f);
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
  my ($j, $error) = get($f);

  defined $error and return (undef, $error);
  defined $j or return (undef, "Unable to retrieve $f");

  @j = @$j;
 }

 if (scalar @j)
 {
  chomp @j;
  s/\n//g foreach @j;
  s/^\s*(#|\/\/).*//g foreach @j;

  my $ret = $coder->decode(join '', @j);

  return ($ret);
 }

 return (undef, "No data was loaded from $f");
}

sub get
{
 return curl('GET', @_);
}

sub curl
{
 my $mode = shift @_;
 my $url = shift @_;

 my $run = <<EOHIPPUS;
$curl -s $mode $url |
EOHIPPUS

 print STDERR "Running: $run\n";
 open my $c, $run or return (undef, "Could not run command [$run]: $!");
 return ([<$c>], undef);
}

sub hashref_search
{
 my $ref = shift @_;
 my $k = shift @_;
 if (ref $ref eq 'HASH' && exists $ref->{$k})
 {
  if (scalar @_ > 0) # dig further
  {
   return hashref_search($ref->{$k}, @_);
  }
  else
  {
   return $ref->{$k};
  }
 }

 if (ref $ref eq 'ARRAY' && ref $k eq 'HASH') # search an array
 {
  foreach my $item (@$ref)
  {
   foreach my $probe (keys %$k)
   {
    if (ref $item eq 'HASH' &&
        exists $item->{$probe})
    {
     # if the value is undef...
     return $item unless defined $k->{$probe};
     # or it matches the probe
     return $item if $item->{$probe} eq $k->{$probe};
    }
   }
  }
 }

 return undef;
}

# 1;
