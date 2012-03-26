#!/usr/bin/perl

use warnings;
use strict;
use File::Find;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use Modern::Perl;               # needs apt-get libmodern-perl
use JSON::XS;                   # needs apt-get libjson-xs-perl

$| = 1;                         # autoflush

my $coder = JSON::XS->new()->relaxed()->utf8()->allow_nonref();

my %options =
 (
  verbose    => 0,
  quiet      => 0,
  help       => 0,
  repolist   => [],
  configfile => glob('~/.cfsketch.conf'),
 );

my @options_spec =
 (
  "quiet|qq!",
  "help!",
  "verbose!",
  "configfile|cf=s",

  "config!",
  "interactive!",
  "repolist=s@",
  "install=s@",
  "activate=s",                 # activate only one at a time
  "deactivate=s",               # deactivate only one at a time
  "remove=s@",
  "test=s@",
  "search=s@",
 );

GetOptions (
            \%options,
            @options_spec,
           );

if ($options{help})
{
 print <DATA>;
 exit;
}

if (open(my $cfh, '<', $options{configfile}))
{
 while (<$cfh>)
 {
  # only look at the first line of the file
  my $given = $coder->decode($_);

  foreach (sort keys %$given)
  {
   say "(read from $options{configfile}) $_ = ", $coder->encode($given->{$_})
    unless $options{quiet};
   $options{$_} = $given->{$_};
  }
  last;
 }
}

say "Full configuration: ", $coder->encode(\%options) if $options{verbose};

my $verbose = $options{verbose};
my $quiet   = $options{quiet};

if ($options{config})
{
 configure_self($options{configfile}, $options{interactive}, shift);
 exit;
}

foreach my $word (qw/search install activate deactivate remove test/)
{
 if ($options{$word})
 {
  # TODO: hack to replace a method table, eliminate
  no strict 'refs';
  $word->($options{$word});
  use strict 'refs';
 }
}

sub configure_self
{
 my $cf    = shift @_;
 my $inter = shift @_;
 my $data  = shift @_;

 my @keys = qw/repolist/;

 my %config;

 if ($inter)
 {
  foreach my $key (@keys)
  {
   print "$key: ";
   my $answer = <>;
   chomp $answer;
   $config{$key} = [split ',', $answer];
  }
 }
 else
 {
  die "You need to pass a filename to --config if you don't --interactive"
   unless $data;

  open(my $dfh, '<', $data)
   or die "Could not open configuration input file $data: $!";

  while (<$dfh>)
  {
   my ($key, $v) = split ',', $_, 2;
   $config{$key} = [split ',', $v];
  }
 }

 open(my $cfh, '>', $cf)
  or die "Could not write configuration input file $cf: $!";

 print $cfh $coder->encode(\%config);
}

sub search
{
 my $terms = shift @_;

 foreach my $repo (@{$options{repolist}})
 {
  say "Looking for terms [@$terms] in cfsketch repository [$repo]"
   if $verbose;

  my $contents = repo_get_contents($repo);

  say "Inspecting repo contents: ", $coder->encode($contents)
   if $verbose;
 }
}

# TODO: need functions for: install activate deactivate remove test

sub repo_get_contents
{
 my $repo = shift @_;

 if ($repo =~ m,^[/\.],)        # just a file path
 {
  if (chdir $repo)
  {
   my %contents;

   find(sub
        {
         my $f = $_;
         if ($f eq 'sketch.json')
         {
          open(my $j, '<', $f)
           or warn "Could not inspect $File::Find::name: $!";

          if ($j)
          {
           my @j = <$j>;
           chomp @j;
           s/\n//g foreach @j;
           s/^\s*#.*//g foreach @j;
           my $json = $coder->decode(join '', @j);
           # TODO: validate more thoroughly?
           if (ref $json eq 'HASH' &&
               exists $json->{manifest}  && ref $json->{manifest}  eq 'HASH' &&
               exists $json->{metadata}  && ref $json->{metadata}  eq 'HASH' &&
               exists $json->{metadata}->{name} &&
               exists $json->{interface} && ref $json->{interface} eq 'HASH')
           {
            $json->{dir} = $File::Find::dir;
            $contents{$json->{metadata}->{name}} = $json;
           }
           else
           {
            warn "Invalid sketch definition in $File::Find::name, skipping";
           }
          }
         }
        }, '.');
   return \%contents;
  }
  else
  {
   die "Could not chdir into local repository [$repo]: $!"
  }
 }
 else
 {
  die "No remote repositories (i.e. $repo) are supported yet"
 }

 return undef;
}

__DATA__

Help for cfsketch

Document the options:

repolist
  "config!",
  "interactive!",
  "install=s@",
  "activate=s",                 # activate only one at a time
  "deactivate=s",               # deactivate only one at a time
  "remove=s@",
  "test=s@",
  "search=s@",
