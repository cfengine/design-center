#!/usr/bin/perl

use warnings;
use strict;
use File::Compare;
use File::Copy;
use File::Find;
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use Modern::Perl;               # needs apt-get libmodern-perl
use JSON::XS;                   # needs apt-get libjson-xs-perl

use constant SKETCH_DEF_FILE => 'sketch.json';

$| = 1;                         # autoflush

my $coder = JSON::XS->new()->relaxed()->utf8()->allow_nonref();

my %options =
 (
  verbose    => 0,
  quiet      => 0,
  help       => 0,
  configfile => $> == 0 ? '/etc/cfsketch/cfsketch.conf' : glob('~/.cfsketch.conf'),
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
   next if exists $options{$_};
   say "(read from $options{configfile}) $_ = ", $coder->encode($given->{$_})
    unless $options{quiet};
   $options{$_} = $given->{$_};
  }
  last;
 }
}

foreach (@{$options{repolist}})
{
 my $abs = File::Spec->rel2abs($_);
 if ($abs ne $_)
 {
  say "Remapped $_ to $abs so it's not relative"
   if $options{verbose};
  $_ = $abs;
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
   my $answer = <>;             # TODO: use the right Readline module
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

 ensure_dir(dirname($cf));
 open(my $cfh, '>', $cf)
  or die "Could not write configuration input file $cf: $!";

 print $cfh $coder->encode(\%config);
}

sub ensure_dir
{
 my $dir = shift @_;

 make_path($dir, { verbose => $verbose });
 return -d $dir;
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

  foreach my $sketch (sort keys %$contents)
  {
   # TODO: improve this search
   my $as_str = $sketch . ' ' . $coder->encode($contents->{$sketch});

   foreach my $term (@$terms)
   {
    next unless $as_str =~ m/$term/;
    say "$contents->{$sketch}->{dir} $sketch";
    last;
   }
  }
 }
}

sub install
{
 my $sketch_dirs = shift @_;
 # make sure we only work with absolute directories
 my $sketches = find_sketches(map { File::Spec->rel2abs($_) } @$sketch_dirs);

 my $dest;
 foreach my $target (@{$options{repolist}})
 {
  if (is_repo_local($target))
  {
   $dest = $target;
   last;
  }
 }

 die "Can't install: none of [@{$options{repolist}}] exist locally!"
  unless defined $dest;

 foreach my $sketch (sort keys %$sketches)
 {
  my $data = $sketches->{$sketch};

  say sprintf('Installing %s (%s) into %s',
              $sketch,
              $data->{file},
              $dest)
   if $verbose;

  my $install_dir = File::Spec->catdir($dest,
                                       split('::', $sketch),
                                      );
  if (ensure_dir($install_dir))
  {
   say "Created destination directory $install_dir" if $verbose;
   foreach my $file (SKETCH_DEF_FILE, sort keys %{$data->{manifest}})
   {
    my $file_spec = $data->{manifest}->{$file};
    # build a locally valid install path, while the manifest can use / separator
    my $source = File::Spec->catfile($data->{dir}, split('/', $file));
    my $dest = File::Spec->catfile($install_dir, split('/', $file));

    my $dest_dir = dirname($dest);
    die "Could not make destination directory $dest_dir"
     unless ensure_dir($dest_dir);

    # TODO: maybe disable this?  It can be expensive for large files.
    if (compare($source, $dest) == 0)
    {
     warn "Manifest member $file is already installed in $dest"
      if $verbose;
    }

    copy($source, $dest) or die "Aborting: copy $source -> $dest failed: $!";

    chmod oct($file_spec->{perm}), $dest if exists $file_spec->{perm};

    if (exists $file_spec->{user})
    {
     # TODO: ensure this works on platforms without getpwnam
     # TODO: maybe add group support too
     my ($login,$pass,$uid,$gid) = getpwnam($file_spec->{user})
      or die "$file_spec->{user} not in passwd file";

     chown $uid, $gid, $dest;
    }
   }

   say "Done installing $sketch";
  }
  else
  {
   warn "Could not make install directory $install_dir, skipping $sketch";
  }
 }
}

# TODO: need functions for: activate deactivate remove test

sub find_sketches
{
 my @dirs = @_;
 my %contents;

 find(sub
      {
       my $f = $_;
       if ($f eq SKETCH_DEF_FILE)
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
             exists $json->{interface} && ref $json->{interface} eq 'HASH') {
          $json->{dir} = $File::Find::dir;
          $json->{file} = $File::Find::name;
          # note this name will be stringified even if it's not a string
          $contents{$json->{metadata}->{name}} = $json;
         }
         else
         {
          warn "Invalid sketch definition in $File::Find::name, skipping";
         }
        }
       }
      }, @dirs);

 return \%contents;
}

sub is_repo_local
{
 my $repo = shift @_;
 return -d $repo;  # just a file path
}

{
 my %content_cache;
 sub repo_get_contents
 {
  my $repo = shift @_;

  return $content_cache{$repo} if exists $content_cache{$repo};

  if (is_repo_local($repo))
  {
   my $contents = find_sketches($repo);
   $content_cache{$repo} = $contents;

   return $contents;
  }
  else
  {
   die "No remote repositories (i.e. $repo) are supported yet"
  }

  warn "Unhandled repo format: $repo";
  return undef;
 }

 sub repo_clear_cache
 {
  %content_cache = ();
 }
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
