#!/usr/bin/perl

use warnings;
use strict;
use List::MoreUtils;
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
  force      => 0,
  # switched depending on root or non-root
  act_file   => $> == 0 ? '/etc/cfsketch/activations.conf' : glob('~/.cfsketch.activations.conf'),
  configfile => $> == 0 ? '/etc/cfsketch/cfsketch.conf' : glob('~/.cfsketch.conf'),
 );

my @options_spec =
 (
  "quiet|qq!",
  "help!",
  "verbose!",
  "force!",
  "configfile|cf=s",
  "ipolicy=s",
  "act_file=s",

  "config!",
  "interactive!",
  "repolist=s@",
  "install=s@",
  "activate=s",                 # activate only one at a time
  "deactivate=s",               # deactivate only one at a time
  "remove=s@",
  "test=s@",
  "search=s@",
  "list!",
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

if ($options{list})
{
 search(['.']);                   # matches everything
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

 my %keys = (
             repolist => 1,             # array
            );

 my %config;

 if ($inter)
 {
  foreach my $key (sort keys %keys)
  {
   print "$key: ";
   my $answer = <>;             # TODO: use the right Readline module
   chomp $answer;
   $config{$key} = $keys{$key} ? [split ',', $answer] : $answer;
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

sub search
{
 my $terms = shift @_;

 foreach my $repo (@{$options{repolist}})
 {
  say "Looking for terms [@$terms] in cfsketch repository [$repo]"
   if $verbose;

  my $local = is_repo_local($repo) ? 'local' : 'remote';

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
    # this format is easy to parse, even if the directory has spaces,
    # because the first two fields won't have spaces
    say "$local $sketch $contents->{$sketch}->{dir}";
    last;
   }
  }
 }
}

sub activate
{
 my $sketch = shift @_;

 die "Can't activate sketch $sketch without valid file from --ipolicy"
  unless ($options{ipolicy} && -f $options{ipolicy});

 my $installed = 0;
 foreach my $repo (@{$options{repolist}})
 {
  my $contents = repo_get_contents($repo);
  if (exists $contents->{$sketch})
  {
   my $data = $contents->{$sketch};
   my $if = $data->{interface};

   # TODO: we could load the policy from a pipe or a network resource too
   say "Loading activation policy from $options{ipolicy}";
   my $policy = load_json($options{ipolicy});

   die "Could not load activation policy from $options{ipolicy}"
    unless ref $policy eq 'HASH';

   foreach my $varname (sort keys %$if)
   {
    die "Can't activate $sketch: its interface requires variable $varname"
     unless exists $policy->{$varname};

    say "Satisfied by policy: $varname" if $verbose;
   }

   # activation successful, now install it
   my $activations = load_json($options{act_file});
   ensure_dir(dirname($options{act_file}));
   if (grep { $_ eq $options{ipolicy} } @{$activations->{$sketch}})
   {
    say "Already active: $sketch policy $options{ipolicy}";
   }
   else
   {
    $activations->{$sketch} = [
                               List::MoreUtils->uniq(@{$activations->{$sketch}},
                                                     $options{ipolicy})
                              ];

    open(my $ach, '>', $options{act_file})
     or die "Could not write activation file $options{act_file}: $!";

    print $ach $coder->encode($activations);
    close $ach;

    say "Activated: $sketch policy $options{ipolicy}";
   }

   $installed = 1;
   last;
  }
 }

 die "Could not activate sketch $sketch, it was not in [@{$options{repolist}}]"
  unless $installed;
}

sub remove
{
 my $toremove = shift @_;

 foreach my $repo (@{$options{repolist}})
 {
  next unless is_repo_local($repo);

  my $contents = repo_get_contents($repo);

  foreach my $sketch (sort @$toremove)
  {
   my @matches = grep
   {
    # accept sketch name or directory
    ($_ eq $sketch) || ($contents->{$_}->{dir} eq $sketch)
   } keys %$contents;

   next unless scalar @matches;
   $sketch = shift @matches;
   my $data = $contents->{$sketch};
   if (remove_dir($data->{dir}))
   {
    say "Successfully removed $sketch from $data->{dir}";
   }
   else
   {
    say "Could not remove $sketch from $data->{dir}";
   }
  }
 }
}

sub install
{
 my $sketch_dirs = shift @_;
 # make sure we only work with absolute directories
 my $sketches = find_sketches(map { File::Spec->rel2abs($_) } @$sketch_dirs);

 my $dest_repo = get_local_repo();

 die "Can't install: none of [@{$options{repolist}}] exist locally!"
  unless defined $dest_repo;

 foreach my $sketch (sort keys %$sketches)
 {
  my $data = $sketches->{$sketch};

  say sprintf('Installing %s (%s) into %s',
              $sketch,
              $data->{file},
              $dest_repo)
   if $verbose;

  my $install_dir = File::Spec->catdir($dest_repo,
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
    if (!$options{force} && compare($source, $dest) == 0)
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

    say "Installed file: $source -> $dest";
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
        my $json = load_json($File::Find::name);

        # TODO: validate more thoroughly?
        if (defined $json && ref $json eq 'HASH' &&
            exists $json->{manifest}  && ref $json->{manifest}  eq 'HASH' &&
            exists $json->{metadata}  && ref $json->{metadata}  eq 'HASH' &&
            exists $json->{metadata}->{name} &&
            exists $json->{interface} && ref $json->{interface} eq 'HASH')
        {
         $json->{dir} = $File::Find::dir;
         $json->{file} = $File::Find::name;
         # note this name will be stringified even if it's not a string
         $contents{$json->{metadata}->{name}} = $json;
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

sub get_local_repo
{
 my $repo;
 foreach my $target (@{$options{repolist}})
 {
  if (is_repo_local($target))
  {
   $repo = $target;
   last;
  }
 }
 return $repo;
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

# Utility functions follow

sub load_json
{
 # TODO: improve this
 my $f = shift @_;

 my $j;
 unless (open($j, '<', $f))
 {
  warn "Could not inspect $f: $!";
  return;
 }

 if ($j)
 {
  my @j = <$j>;
  chomp @j;
  s/\n//g foreach @j;
  s/^\s*#.*//g foreach @j;
  my $ret = $coder->decode(join '', @j);

  if (ref $ret eq 'HASH' &&
      exists $ret->{include} && ref $ret->{include} eq 'ARRAY')
  {
   foreach my $include (@{$ret->{include}})
   {
    if (dirname($include) eq '.' && ! -f $include)
    {
     $include = File::Spec->catfile(dirname($f), $include);
    }

    say "Including $include";
    my $parent = load_json($include);
    if (ref $parent eq 'HASH')
    {
     $ret->{$_} = $parent->{$_} foreach keys %$parent;
    }
    else
    {
     warn "Malformed include contents from $include: not a hash";
    }
   }
  }

  return $ret;
 }

 return;
}

sub ensure_dir
{
 my $dir = shift @_;

 make_path($dir, { verbose => $verbose });
 return -d $dir;
}

sub remove_dir
{
 my $dir = shift @_;

 return remove_tree($dir, { verbose => $verbose });
}

__DATA__

Help for cfsketch

Document the options:
