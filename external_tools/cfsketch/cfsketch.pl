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
use Template;
use Digest::MD5 qw(md5_hex);

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
  copbl_file => $> == 0 ? '/etc/cfsketch/lib/cfengine_stdlib.cf' : glob('~/.cfsketch/lib/cfengine_stdlib.cf'),
  act_file   => $> == 0 ? '/etc/cfsketch/activations.conf' : glob('~/.cfsketch/activations.conf'),
  configfile => $> == 0 ? '/etc/cfsketch/cfsketch.conf' : glob('~/.cfsketch/cfsketch.conf'),
 );

my @options_spec =
 (
  "quiet|qq!",
  "help!",
  "verbose!",
  "force!",
  "configfile|cf=s",
  "params=s",
  "act_file=s",
  "copbl_file=s",

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
  "generate!",
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

foreach my $word (qw/search install activate deactivate remove test generate/)
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
             copbl_file => 0,           # scalar
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
  my $local = is_repo_local($repo) ? 'local' : 'remote';
  my @sketches = search_internal($repo, $terms);

  my $contents = repo_get_contents($repo);

  foreach my $sketch (@sketches)
  {
   # this format is easy to parse, even if the directory has spaces,
   # because the first two fields won't have spaces
   say "$local $sketch $contents->{$sketch}->{dir}";
  }
 }
}

sub search_internal
{
 my $repo  = shift @_;
 my $terms = shift @_;

 my @ret;

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
   push @ret, $sketch;
   last;
  }
 }

 return @ret;
}

# generate the actual cfengine config that will run all the cfsketch bundles
sub generate
{
   # activation successful, now install it
   my $activations = load_json($options{act_file});
   die "Can't load any activations from $options{act_file}"
    unless defined $activations && ref $activations eq 'HASH';

   # maybe make the run template configurable?
   my $run_template = 'run.tmpl';

   my $template = Template->new({
                                 INCLUDE_PATH => dirname($0),
                                 INTERPOLATE  => 1,
                                 EVAL_PERL    => 1,
                                });

 ACTIVATION:
   foreach my $sketch (sort keys %$activations)
   {
    my $prefix = $sketch;
    $prefix =~ s/::/__/g;

    foreach my $repo (@{$options{repolist}})
    {
     my $contents = repo_get_contents($repo);
     if (exists $contents->{$sketch})
     {
      foreach my $params (@{$activations->{$sketch}})
      {
       say "Loading activation params for sketch $sketch from $params"
        if $verbose;
       my $pdata = load_json($params);
       die "Couldn't load activation params for $sketch from $params: $!"
        unless defined $pdata;

       my $data = $contents->{$sketch};
       my $if = $data->{interface};
       my $entry = $data->{entry_point};

       my $input = 'run.tmpl';
       my $output = '';

       my %types;
       my %booleans;
       my %vars;

       foreach my $k (sort keys %$if)
       {
        my $cfengine_k = "${prefix}::$k";
        $cfengine_k =~ s/::/__/g;

        my $v = $pdata->{$k};
        my $definition = $if->{$k};

        if (ref $definition ne 'HASH')
        {
         # TODO: add more variable types handled here, including
         # "list of integers" and such
         if ($definition eq 'boolean' ||
             $definition eq 'string' ||
             $definition eq 'integer')
         {
          $definition = { type => $definition };
         }
        }

        if (ref $definition ne 'HASH')
        {
         die "Can't parse definition of $k: " . Dumper($definition);
        }

        my $list = 0;
        my $def1 = $definition;

        # TODO: add more variable types here
        if (exists $definition->{list})
        {
         $list = 1;
         $def1 = $definition->{list};
        }

        if ($def1->{type} eq 'boolean' && !$list)
        {
         $booleans{$cfengine_k} = $v;
        }
        elsif ($list)
        {
         $vars{$cfengine_k} = '{ ' . join(',', map { "\"$_\"" } @$v) . ' }';
         $types{$cfengine_k} = 'slist';
        }
        else
        {
         $vars{$cfengine_k} = "\"$v\"";
         $types{$cfengine_k} = 'string';
        }
       }

       # process input template, substituting variables
       $template->process($input,
                          {
                           repo        => $repo,
                           sketch      => $sketch,
                           entry_point => $entry->[1],
                           inputs      => sprintf('"%s"', $entry->[0]),
                           types       => \%types,
                           booleans    => \%booleans,
                           vars        => \%vars,
                           prefix      => $prefix,
                  }, \$output)
        || die $template->error();

       my $run_name = "${prefix}__$params.cf";
       $run_name =~ s/[\.\/]/_/g;
       $run_name =~ s/\.json\.cf/.cf/;
       my $run_file = File::Spec->catfile($data->{dir}, $run_name);
       open(my $rf, '>', $run_file)
        or die "Could not write run file $run_file: $!";

       print $rf $output;
       close $rf;
       say "Generated activated params $params for sketch $sketch into $run_file";
      }
      next ACTIVATION;
     }
    }
    die "Could not find sketch $sketch in repo list @{$options{repolist}}";
   }
}

sub activate
{
 my $sketch = shift @_;

 die "Can't activate sketch $sketch without valid file from --params"
  unless ($options{params} && -f $options{params});

 my $installed = 0;
 foreach my $repo (@{$options{repolist}})
 {
  my $contents = repo_get_contents($repo);
  if (exists $contents->{$sketch})
  {
   my $data = $contents->{$sketch};
   my $if = $data->{interface};

   # TODO: we could load the params from a pipe or a network resource too
   say "Loading activation params from $options{params}";
   my $params = load_json($options{params});

   die "Could not load activation params from $options{params}"
    unless ref $params eq 'HASH';

   my $entry_point = verify_entry_point($sketch,
                                        $data->{dir},
                                        $data->{manifest},
                                        $data->{entry_point},
                                        $data->{interface});

   if ($entry_point)
   {
    my $varlist = $entry_point->{varlist};
    foreach my $varname (sort keys %$varlist)
    {
     die "Can't activate $sketch: its interface requires variable $varname"
      unless exists $params->{$varname};
     say "Satisfied by params: $varname" if $verbose;
    }
   }
   else
   {
     die "Can't activate $sketch: missing entry point in $data->{entry_point}"
   }

   # activation successful, now install it
   my $activations = load_json($options{act_file});
   ensure_dir(dirname($options{act_file}));
   if (grep { $_ eq $options{params} } @{$activations->{$sketch}})
   {
    say "Already active: $sketch params $options{params}";
   }
   else
   {
    $activations->{$sketch} = [
                               List::MoreUtils::uniq(@{$activations->{$sketch}},
                                                     $options{params})
                              ];

    open(my $ach, '>', $options{act_file})
     or die "Could not write activation file $options{act_file}: $!";

    print $ach $coder->encode($activations);
    close $ach;

    say "Activated: $sketch params $options{params}";
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

  my @missing = missing_dependencies($data->{metadata}->{depends});

  if (scalar @missing)
  {
   if ($options{force})
   {
    warn "Installing $sketch despite unsatisfied dependencies @missing";
   }
   else
   {
    die "Can't install: $sketch has unsatisfied dependencies @missing";
   }
  }

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

# TODO: need functions for: deactivate remove test

sub missing_dependencies
{
 my $deps = shift @_;
 my @missing;

 foreach my $repo (@{$options{repolist}})
 {
  my $contents = repo_get_contents($repo);
  foreach my $dep (sort keys %$deps)
  {
   if ($dep eq 'os' &&
       ref $deps->{$dep} eq 'ARRAY')
   {
    # TODO: get uname from cfengine?
    # pick either /bin/uname or /usr/bin/uname
    my $uname_path = -x '/bin/uname' ? '/bin/uname -o' : '/usr/bin/uname -s';
    my $uname = 'unknown';
    if (-x (split ' ', $uname_path)[0])
    {
     $uname = `$uname_path`;
     chomp $uname;
    }

    foreach my $os (sort @{$deps->{$dep}})
    {
     if ($uname =~ m/$os/i)
     {
      say "Satisfied OS dependency: $uname matched $os"
       if $verbose;

      delete $deps->{$dep};
     }
    }

    if (exists $deps->{$dep})
    {
     say "Unsatisfied OS dependencies: $uname did not match [@{$deps->{$dep}}]"
      if $verbose;
    }
   }
   elsif ($dep eq 'cfengine' &&
          ref $deps->{$dep} eq 'HASH' &&
          exists $deps->{$dep}->{version})
   {
    my $cfv = `cf-promises -V`; # TODO: get this from cfengine?
    if ($cfv =~ m/\s+(\d+\.\d+\.\d+)/)
    {
     my $version = $1;
     if ($version ge $deps->{$dep}->{version})
     {
      say("Satisfied cfengine version dependency: $version present, needed ",
       $deps->{$dep}->{version})
       if $verbose;

      delete $deps->{$dep};
     }
     else
     {
      say("Unsatisfied cfengine version dependency: $version present, need ",
       $deps->{$dep}->{version})
       if $verbose;
     }
    }
    else
    {
     say "Unsatisfied cfengine dependency: could not get version from [$cfv]."
      if $verbose;
    }
   }
   elsif ($dep eq 'copbl' &&
          ref $deps->{$dep} eq 'HASH' &&
          exists $deps->{$dep}->{version})
   {
    # TODO: open $options{copbl_file} and get the version
    my $version = "106";
    if ($version ge $deps->{$dep}->{version})
    {
     say("Satisfied COPBL version dependency: $version present, needed ",
         $deps->{$dep}->{version})
      if $verbose;

     delete $deps->{$dep};
    }
    else
    {
     say("Unsatisfied COPBL version dependency: $version present, need ",
         $deps->{$dep}->{version})
      if $verbose;
    }
   }
   elsif (exists $contents->{$dep})
   {
    my $dd = $contents->{$dep};
    # either the version is not specified or it has to match
    if (!exists $deps->{$dep}->{version} ||
        $dd->{metadata}->{version} >= $deps->{$dep}->{version})
    {
     say "Found dependency $dep in $repo" if $verbose;
     # TODO: test recursive dependencies, right now this will loop
     # TODO: maybe use a CPAN graph module
     push @missing, missing_dependencies($dd->{metadata}->{depends});
     delete $deps->{$dep};
    }
    else
    {
     say "Found dependency $dep in $repo but the version doesn't match"
      if $verbose;
    }
   }
  }
 }

 push @missing, sort keys %$deps;
 if (scalar @missing)
 {
  say "Unsatisfied dependencies: @missing";
 }

 return @missing;
}

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

        # TODO: validate more thoroughly?  at least better messaging
        if (
            # the data must be valid and a hash
            defined $json && ref $json eq 'HASH' &&
            # the manifest must be a hash
            exists $json->{manifest}  && ref $json->{manifest}  eq 'HASH' &&

            # the metadata must be a hash...
            exists $json->{metadata}  && ref $json->{metadata}  eq 'HASH' &&

            # with a 'depends' key that points to a hash
            exists $json->{metadata}->{depends}  &&
            ref $json->{metadata}->{depends}  eq 'HASH' &&

            # and a 'name' key
            exists $json->{metadata}->{name} &&

            # entry_point has to point to a file in the manifest
            exists $json->{entry_point} &&
            exists $json->{manifest}->{$json->{entry_point}} &&

            # interface has to point to a file in the manifest
            exists $json->{interface} &&
            exists $json->{manifest}->{$json->{interface}}
           )
        {
         my $name = $json->{metadata}->{name};
         $json->{dir} = $File::Find::dir;
         $json->{file} = $File::Find::name;

         if (verify_entry_point($name,
                                $File::Find::dir,
                                $json->{manifest},
                                $json->{entry_point},
                                $json->{interface}))
         {
          # note this name will be stringified even if it's not a string
          $contents{$name} = $json;
         }
         else
         {
          warn "Could not verify bundle entry point from $File::Find::name";
         }
        }
        else
        {
         warn "Could not load sketch definition from $File::Find::name";
        }
       }
      }, @dirs);

 return \%contents;
}

sub verify_entry_point
{
 my $name      = shift @_;
 my $dir       = shift @_;
 my $mft       = shift @_;
 my $entry     = shift @_;
 my $interface = shift @_;

 my $maincf = $entry;

 my $maincf_filename = File::Spec->catfile($dir, $maincf);
 unless (exists $mft->{$maincf} && -f $maincf_filename)
 {
  warn "Could not find sketch $name entry point '$maincf'";
  return 0;
 }

 my $mcf;
 unless (open($mcf, '<', $maincf_filename))
 {
  warn "Could not open $maincf_filename: $!";
  return 0;
 }

 if ($mcf)
 {
  $. = 0;
  my $bundle;
  my $meta = {
              confirmed => 0,
              varlist => {},
             };

  while (my $line = <$mcf>)
  {
   $.++;
   # TODO: need better cfengine parser; this should be extracted by cf-promises
   # when the meta: section is available.  It's very primitive now.

   if (defined $bundle && $line =~ m/^\s*bundle\s+agent\s+meta_$bundle/)
   {
    $meta->{confirmed} = 1;
   }

   # match "arguments" slist => { "foo", "bar", "baz" };
   if ($meta->{confirmed} && $line =~ m/^\s*
                                        "arguments"
                                        \s+
                                        slist
                                        \s+=>\s+
                                        \{\s+(.+)\}\s*;/x)
   {
    # collect variables
    my $varlist = $1;
    $meta->{varlist} = { map { $_ => undef } ($varlist =~ m/"([^"]+)"/g) };
   }

   # match "argtype[foo]" string => "string";
   # or    "argtype[bar]" string => "slist";
   if (scalar keys %{$meta->{varlist}} &&
       $line =~ m/^\s*
                  "argtype\[([^]]+)\]"
                  \s+
                  string
                  \s+=>\s+
                  "(string|slist)"\s*;/x)
   {
    if (exists $meta->{varlist}->{$1})
    {
     $meta->{varlist}->{$1} = $2;
    }
    else
    {
     warn "Unknown variable $1 defined in [$line]";
    }
   }

   if ($meta->{confirmed} && $line =~ m/^\s*\}\s*/)
   {
    return $meta;
   }

   if ($line =~ m/^\s*bundle\s+agent\s+(\w+)/)
   {
    $bundle = $1;
    say "Found definition of bundle $bundle at $maincf_filename:$." if $verbose;
   }

  }

  if (scalar keys %{$meta->{varlist}})
  {
   warn "Couldn't find the definition for all the variables for [$bundle] in $maincf_filename";
  }
  elsif ($meta->{confirmed})
  {
   warn "Couldn't find the closing } for [$bundle] in $maincf_filename";
  }
  elsif (defined $bundle)
  {
   warn "Couldn't find the meta definition of [$bundle] in $maincf_filename";
  }
  else
  {
   warn "Couldn't find a usable bundle in $maincf_filename";
  }

  return 0;
 }
 else
 {
  warn "Could not load $maincf_filename: $!";
  return 0;
 }
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

- need global run file for all generated

- document cfsketch formats (params, sketch.json, all .conf files)

- sketch composition

- activations in md5_hex("$str$salt")
