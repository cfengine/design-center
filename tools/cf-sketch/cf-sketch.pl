#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use warnings;
use strict;
use List::MoreUtils qw/uniq/;
use File::Compare;
use File::Copy;
use File::Find;
use File::Spec;
use Cwd;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use LWP::Simple;

my $coder;
my $canonical_coder;

BEGIN
{
    eval
    {
     require JSON::XS;
     $coder = JSON::XS->new()->relaxed()->utf8()->allow_nonref();
     # for storing JSON data so it's directly comparable
     $canonical_coder = JSON::XS->new()->canonical()->utf8()->allow_nonref();
    };
    if ($@ )
    {
     warn "Falling back to plain JSON module (you should install JSON::XS)";
     require JSON;
     $coder = JSON->new()->relaxed()->utf8()->allow_nonref();
     # for storing JSON data so it's directly comparable
     $canonical_coder = JSON->new()->canonical()->utf8()->allow_nonref();
    }
}

use constant SKETCH_DEF_FILE => 'sketch.json';

$| = 1;                         # autoflush

# Configuration directory depending on root/non-root
my $configdir = $> == 0 ? '/etc/cf-sketch' : glob('~/.cf-sketch');

my %options = ();

# Default values
my %def_options =
 (
  verbose    => 0,
  quiet      => 0,
  help       => 0,
  force      => 0,
  # switched depending on root or non-root
  'act-file'   => "$configdir/activations.conf",
  configfile => "$configdir/cf-sketch.conf",
  'install-target' => undef,
  'install-source' => local_cfsketches_source(File::Spec->curdir()) || 'https://raw.github.com/cfengine/design-center/master/sketches/cfsketches',
  'make-package' => [],
  params => [],
  cfhome => '/var/cfengine/bin',
  runfile => undef,
 );

my @options_spec =
 (
  "quiet|qq!",
  "help!",
  "verbose|v!",
  "force|f!",
  "cfhome=s",
  "configfile|cf=s",
  "runfile|rf=s",
  "params|p=s@",
  "act-file|af=s",
  "install-target|it=s",
  "json!",

  "save-config",
  "repolist|rl=s@",
  # "make-package=s@",
  "install|i=s@",
  "install-source|is=s",
  "remove|r=s@",
  "activate|a=s",                 # activate only one at a time
  "deactivate|d=s",               # deactivate only one at a time
  "test|t=s@",
  "search|s=s@",
  "list|l:s@",
  "list-activations|la!",
  "generate|g!",
  "api=s",
 );

# Options given on the command line
my %cmd_options;
GetOptions (
            \%cmd_options,
            @options_spec,
           );

if ($cmd_options{help})
{
 print <DATA>;
 exit;
}

# Options given on the config file
my %cfgfile_options;
my $cfgfile = $cmd_options{configfile} || $def_options{configfile};
if (open(my $cfh, '<', $cfgfile))
{
  # slurp the entire file
  my $jsontxt = join("", <$cfh>);
  my $given = $coder->decode($jsontxt);

  foreach (sort keys %$given)
  {
   print "(read from $cfgfile) $_ = ", $coder->encode($given->{$_}), "\n"
    if $cfgfile_options{verbose};
   $cfgfile_options{$_} = $given->{$_};
  }
}

# Now we merge all three sources of options: Default options are
# overriden by config-file options, which are overriden by
# command-line options
foreach my $ptr (\%def_options, \%cfgfile_options, \%cmd_options) {
  foreach my $key (keys %$ptr) {
    $options{$key} = $ptr->{$key};
  }
}

my $happy_root = $> != 0 ? glob("~/.cfagent/inputs") : (-e '/var/cfengine/state/am_policy_hub' ? '/var/cfengine/masterfiles' : '/var/cfengine/inputs');

my $required_version = '3.3.0';
my $version = cfengine_version();

if (!$options{force} && $required_version gt $version)
{
 die "Couldn't ensure CFEngine version [$version] is above required [$required_version], sorry!";
}

$options{repolist} = [ File::Spec->catfile($happy_root, 'sketches') ]
 unless exists $options{repolist};
# Allow both comma-separated values and multiple occurrences of --repolist
$options{repolist} = [ split(/,/, join(',', @{$options{repolist}})) ];

$options{'install-target'} = File::Spec->catfile($happy_root, 'sketches')
 unless $options{'install-target'};

my @list;
foreach my $repo (@{$options{repolist}})
{
 if (is_resource_local($repo))
 {
  my $abs = File::Spec->rel2abs($repo);
  if ($abs ne $repo)
  {
   print "Remapped $repo to $abs so it's not relative\n"
    if $options{verbose};
   $repo = $abs;
  }
 }
 else                                   # a remote repository
 {
 }

 push @list, $repo;
}

$options{repolist} = \@list;

my $verbose = $options{verbose};
my $quiet   = $options{quiet};

print "Full configuration: ", $coder->encode(\%options), "\n" if $verbose;

if ($options{'save-config'})
{
 configure_self($options{configfile});
 exit;
}

if ($options{list})
{
 # 'all' matches everything
 list(($options{list}->[0] eq 'all' || $options{list}->[0] eq '') ?
      ["."] : $options{list});
 exit;
}

if ($options{search})
{
 search($options{search}->[0] eq 'all' ? ["."] : $options{search});
 exit;
}

if (scalar @{$options{'make-package'}})
{
 make_packages($options{'make-package'});
 exit;
}

if ($options{'list-activations'})
{
 my $activations = load_json($options{'act-file'}, 1);
 die "Can't load any activations from $options{'act-file'}"
  unless defined $activations && ref $activations eq 'HASH';
 foreach my $sketch (sort keys %$activations)
 {
  foreach my $pfile (sort keys %{$activations->{$sketch}})
  {
   print "$sketch $pfile ", $coder->encode($activations->{$sketch}->{$pfile}), "\n";
  }
 }
 exit;
}

foreach my $word (qw/search install activate deactivate remove test generate api/)
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

 my %keys = (
             'repolist' => 1,             # array
             'cfhome'   => 0,             # string
             'install-source' => 0,       # string
            );

 print "Saving configuration keys [@{[sort keys %keys]}] to file $cf\n" unless $quiet;

 my %config;

 foreach my $key (sort keys %keys) {
   $config{$key} = $options{$key};
   print "Saving option $key=".tersedump($config{$key})."\n"
     if $verbose;
 }

 ensure_dir(dirname($cf));
 open(my $cfh, '>', $cf)
  or die "Could not write configuration input file $cf: $!";

 print $cfh $coder->pretty(1)->encode(\%config);
}

sub search
{
 my $terms = shift @_;
 my $source = $options{'install-source'};
 my $base_dir = dirname($source);
 my $search = search_internal($source, []);

 SKETCH:
 foreach my $sketch (sort keys %{$search->{known}})
 {
  my $dir = File::Spec->catdir($base_dir, $search->{known}->{$sketch});
  foreach my $term (@$terms)
  {
   if ($sketch =~ m/$term/ || $dir =~ m/$term/)
   {
    print "$sketch $dir\n";
    next SKETCH;
   }
  }
 }
}

sub search_internal
{
 my $source = shift @_;
 my $sketches = shift @_;

 my %known;
 my %todo;
 my $local = is_resource_local($source);

 if ($local)
 {
  open(my $invf, '<', $source)
   or die "Could not open cf-sketch inventory file $source: $!";

  while (<$invf>)
  {
   my $line = $_;

   my ($dir, $sketch, $etc) = (split ' ', $line, 3);
   $known{$sketch} = $dir;

   foreach my $s (@$sketches)
   {
    next unless ($sketch eq $s || $dir eq $s);
    $todo{$sketch} = $dir;
   }
  }
 }
 else
 {
  my $invd = get($source)
   or die "Unable to retrieve $source : $!\n";

  my @lines = split "\n", $invd;
  foreach my $line (@lines)
  {
   my ($dir, $sketch, $etc) = (split ' ', $line, 3);
   $known{$sketch} = $dir;

   foreach my $s (@$sketches)
   {
    next unless ($sketch eq $s || $dir eq $s);
    $todo{$sketch} = $dir;
   }
  }
 }

 return { known => \%known, todo => \%todo };
}

sub list
{
 my $terms = shift @_;

 foreach my $repo (@{$options{repolist}})
 {
  my @sketches = list_internal($repo, $terms);

  my $contents = repo_get_contents($repo);

  foreach my $sketch (@sketches)
  {
   # this format is easy to parse, even if the directory has spaces,
   # because the first two fields won't have spaces
   my @docs = grep {
    $contents->{$sketch}->{manifest}->{$_}->{documentation}
   } sort keys %{$contents->{$sketch}->{manifest}};

   print "$sketch $contents->{$sketch}->{dir}\n\t@docs\n";
  }
 }
}

sub list_internal
{
 my $repo  = shift @_;
 my $terms = shift @_;

 my @ret;

 print "Looking for terms [@$terms] in cf-sketch repository [$repo]\n"
  if $verbose;

 my $contents = repo_get_contents($repo);
 print "Inspecting repo contents: ", $coder->encode($contents), "\n"
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

# generate the actual cfengine config that will run all the cf-sketch bundles
sub generate
{
   # activation successful, now install it
   my $activations = load_json($options{'act-file'}, 1);
   die "Can't load any activations from $options{'act-file'}"
    unless defined $activations && ref $activations eq 'HASH';

   my $activation_counter = 1;
   my $template_activations = {};

   my @inputs;
   my %dependencies;

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
      foreach my $params (sort keys %{$activations->{$sketch}})
      {
       print "Loading activation for sketch $sketch (originally from $params)\n"
        if $verbose;
       my $pdata = $activations->{$sketch}->{$params};
       die "Couldn't load activation params for $sketch: $!"
        unless defined $pdata;

       my $data = $contents->{$sketch};

       my %types;
       my %booleans;
       my %vars;

       my $entry_point = verify_entry_point($sketch,
                                            $data->{dir},
                                            $data->{manifest},
                                            $data->{entry_point},
                                            $data->{interface});

       die "Could not load the entry point definition of $sketch"
        unless $entry_point;

       # for null entry_point and interface definitions, don't write
       # anything in the runme template
       unless (exists $entry_point->{bundle})
       {
        push @inputs, File::Spec->catfile($data->{dir}, @{$data->{interface}});
        next;
       }

       my $activation = {
                         file => File::Spec->catfile($data->{dir}, $data->{entry_point}),
                         entry_bundle => $entry_point->{bundle},
                         params => $params,
                         sketch => $sketch,
                         prefix => $prefix,
                        };

       my $varlist = $entry_point->{varlist};

       # force-feed the bundle location here to work around a possible this.promise_filename bug
       $varlist->{bundle_home} = 'string';
       $pdata->{bundle_home} = $data->{dir};

       # provide the metadata that could be useful
       my @files = sort keys %{$data->{manifest}};
       $varlist->{sketch_manifest} = 'slist';
       $pdata->{sketch_manifest} = [ @files ];

       $varlist->{sketch_manifest_docs} = 'slist';
       $pdata->{sketch_manifest_docs} = [ sort grep { $data->{manifest}->{$_}->{documentation} } @files ];

       $varlist->{sketch_manifest_cf} = 'slist';
       $pdata->{sketch_manifest_cf} = [ sort grep { $_ =~ m/\.cf$/ } @files ];

       my %leftovers = %{$data->{manifest}};
       delete $leftovers{$_} foreach (@{$pdata->{sketch_manifest_cf}}, @{$pdata->{sketch_manifest_docs}});
       if (scalar keys %leftovers)
       {
        $varlist->{sketch_manifest_extra} = 'slist';
        $pdata->{sketch_manifest_extra} = [ sort keys %leftovers ];
       }

       $varlist->{sketch_authors} = 'slist';
       $pdata->{sketch_authors} = [ sort @{$data->{metadata}->{authors}} ];

       $varlist->{sketch_portfolio} = 'slist';
       $pdata->{sketch_portfolio} = [ sort @{$data->{metadata}->{portfolio}} ];

       $dependencies{$_} = 1 foreach collect_dependencies($data->{metadata}->{depends});

       $varlist->{sketch_depends} = 'slist';
       $pdata->{sketch_depends} = [ sort keys %dependencies ];

       foreach my $key (qw/version name license/)
       {
        $varlist->{"sketch_$key"} = 'string';
        $pdata->{"sketch_$key"} = '' . $data->{metadata}->{$key};
       }

       my $optional_varlist = $entry_point->{optional_varlist};
       foreach my $k (sort keys %$varlist, sort keys %$optional_varlist)
       {
        my $cfengine_k = "${prefix}::$k";
        $cfengine_k =~ s/::/__/g;

        if (exists $entry_point->{default}->{$k} &&
            !exists $pdata->{$k})
        {
         $pdata->{$k} = $entry_point->{default}->{$k};
        }

        # skip optional variables without a value
        next if (exists $optional_varlist->{$k} && ! exists $pdata->{$k});

        my $v = $pdata->{$k};
        my $augment_v = $pdata->{"+$k"};

        die "Supplied augment variable for key $k is not an array"
         if ($augment_v && ref $augment_v ne 'HASH');

        my $definition = exists $optional_varlist->{$k} ?
         $entry_point->{optional_varlist}->{$k} :
          $entry_point->{varlist}->{$k};

        if ($definition eq 'context')
        {
         $activation->{contexts}->{$cfengine_k}->{value} = $v;
        }
        elsif ($definition eq 'slist')
        {
         $activation->{vars}->{$cfengine_k}->{value} = '{ ' . join(',', map { "\"$_\"" } @$v) . ' }';
         $activation->{vars}->{$cfengine_k}->{type} = 'slist';
        }
        elsif ($definition eq 'array')
        {
         die "Unable to activate: provided value " .
          $coder->encode($v) . " for key $k is not an array"
           unless ref $v eq 'HASH';

         $activation->{array_vars}->{$cfengine_k} = $v;
         if ($augment_v)
         {
          $activation->{array_vars}->{$cfengine_k}->{$_} = $augment_v->{$_}
           foreach keys %$augment_v;
         }

         die "Sorry, but you can't activate with an empty list in $k"
          unless scalar keys %{$activation->{array_vars}->{$cfengine_k}};
        }
        else
        {
         # primitive extractor of function calls
         if ($v =~ m/^\w+\(.+\)/)
         {
          $activation->{vars}->{$cfengine_k}->{value} = $v;
         }
         else
         {
          $activation->{vars}->{$cfengine_k}->{value} = "\"$v\"";
         }

         $activation->{vars}->{$cfengine_k}->{type} = 'string';
        }
       }

       my $ak = sprintf('%03d', $activation_counter++);
       $template_activations->{$ak} = $activation;
      }

      next ACTIVATION;
     }
    }
    die "Could not find sketch $sketch in repo list @{$options{repolist}}";
   }

   foreach my $repo (@{$options{repolist}})
   {
    my $contents = repo_get_contents($repo);
    foreach my $dep (keys %dependencies)
    {
     if (exists $contents->{$dep})
     {
      push @inputs, File::Spec->catfile($contents->{$dep}->{dir},
                                        @{$contents->{$dep}->{interface}});
      delete $dependencies{$dep};
     }
    }
   }

   my @deps = keys %dependencies;
   if (scalar @deps)
   {
    die "Sorry, can't generate: unsatisfied dependencies [@deps]";
   }

   # process input template, substituting variables
   push @inputs, $template_activations->{$_}->{file}
    foreach sort keys %$template_activations;

   my $includes = join ', ', map { "\"$_\"" } uniq(@inputs);

   # maybe make the run template configurable?
   my $output = make_runfile($template_activations, $includes);

   my $run_file = $options{runfile} || File::Spec->catfile($happy_root, 'cf-sketch-runfile.cf');
   open(my $rf, '>', $run_file)
    or die "Could not write run file $run_file: $!";

   print $rf $output;
   close $rf;
   print "Generated run file $run_file\n"
    unless $quiet;

}

sub api
{
 my $sketch = shift @_;

 my $found = 0;
 foreach my $repo (@{$options{repolist}})
 {
  my $contents = repo_get_contents($repo);
  if (exists $contents->{$sketch})
  {
   my $data = $contents->{$sketch};
   my $if = $data->{interface};

   my $entry_point = verify_entry_point($sketch,
                                        $data->{dir},
                                        $data->{manifest},
                                        $data->{entry_point},
                                        $data->{interface});

   if ($entry_point)
   {
     $found = 1;
     my @mandatory_args = grep { $_ ne 'activated' } keys %{$entry_point->{varlist}};
     my @optional_args = keys %{$entry_point->{optional_varlist}};
     local $Data::Dumper::Terse = 1;
     local $Data::Dumper::Indent = 0;
     my %defaults = map { $_ => Dumper($entry_point->{default}->{$_})} @optional_args;
     my %empty_values = ( 'context' => 'false',
                          'string'  => '',
                          'slist'   => [],
                          'array'   => {},
                        );
     if ($options{json}) {
       my %params = ();
       $params{$_} = $empty_values{$entry_point->{varlist}->{$_}} foreach (@mandatory_args);
       $params{$_} = $entry_point->{default}->{$_} foreach (@optional_args);
       print $coder->pretty(1)->encode(\%params)."\n";
     }
     else {
       print "Sketch $sketch\n";
       if ($data->{entry_point}) {
         print "  Entry bundle name: $entry_point->{bundle}\n";
         if (scalar @mandatory_args) {
           print "  Mandatory arguments:\n";
           foreach my $arg (@mandatory_args) {
             print "    $arg: $entry_point->{varlist}->{$arg}\n";
           }
         }
         else {
           print "  No mandatory arguments.\n";
         }
         if (scalar @optional_args) {
           print "  Optional arguments:\n";
           foreach my $arg (@optional_args) {
             print "    $arg: $entry_point->{optional_varlist}->{$arg} (default value: $defaults{$arg})\n";
           }
         }
         else {
           print "  No optional arguments.\n";
         }
       }
       else {
         print "  This is a library sketch - no entry point defined.\n";
       }
     }
   }
   else {
     die "I cannot find API information about $sketch.\n";
   }
 }
}
 unless ($found) {
   die "I could not find sketch $sketch. It doesn't seem to be installed.\n";
 }
}

sub activate
{
 my $sketch = shift @_;

 die "Can't activate sketch $sketch without --params"
  unless scalar @{$options{params}};

 my $params = {};

 my $p = $options{params};
 my $pname = join "; ", @$p;

 if (scalar @$p && -f $p->[0] || !is_resource_local($p->[0]))
 {
  print "Loading activation params from $p->[0]\n" unless $quiet;
  $params = load_json($p->[0]);

  die "Could not load activation params from $p->[0]"
   unless ref $params eq 'HASH';

  shift @$p;
 }
 
 foreach my $extra (@$p)
 {
  next unless $extra =~ m/([^=]+)=(.*)/;
  $params->{$1} = $2;
 }

 my $installed = 0;
 foreach my $repo (@{$options{repolist}})
 {
  my $contents = repo_get_contents($repo);
  if (exists $contents->{$sketch})
  {
   my $data = $contents->{$sketch};
   my $if = $data->{interface};

   my $entry_point = verify_entry_point($sketch,
                                        $data->{dir},
                                        $data->{manifest},
                                        $data->{entry_point},
                                        $data->{interface});

   if ($entry_point)
   {
    foreach my $default_k (keys %{$entry_point->{default}})
    {
     next if exists $params->{$default_k};
     $params->{$default_k} = $entry_point->{default}->{$default_k};
    }

    my $varlist = $entry_point->{varlist};
    foreach my $varname (sort keys %$varlist)
    {
     die "Can't activate $sketch: its interface requires variable $varname"
      unless exists $params->{$varname};
     print "Satisfied by params: $varname\n" if $verbose;
    }

    $varlist = $entry_point->{optional_varlist};
    foreach my $varname (sort keys %$varlist)
    {
     next unless exists $params->{$varname};
     print "Optional satisfied by params: $varname\n" if $verbose;
    }
   }
   else
   {
     die "Can't activate $sketch: missing entry point in $data->{entry_point}"
   }

   # activation successful, now install it
   my $activations = load_json($options{'act-file'}, 1);

   if (exists $activations->{$sketch}->{$pname})
   {
    my $p = $canonical_coder->encode($activations->{$sketch}->{$pname});
    my $q = $canonical_coder->encode($params);
    if ($p eq $q)
    {
     if ($options{force})
     {
      warn "Activating duplicate parameters [$q] because of --force"
       unless $quiet;
     }
     else
     {
      die "Can't activate: $sketch has already been activated with $q";
     }
    }
   }

   $activations->{$sketch}->{$pname} = $params;

   ensure_dir(dirname($options{'act-file'}));
   open(my $ach, '>', $options{'act-file'})
    or die "Could not write activation file $options{'act-file'}: $!";

   print $ach $coder->encode($activations);
   close $ach;

   print "Activated: $sketch params $pname\n" unless $quiet;

   $installed = 1;
   last;
  }
 }

 die "Could not activate sketch $sketch, it was not in the given list of repositories [@{$options{repolist}}]"
  unless $installed;
}

sub deactivate
{
 my $sketch = shift @_;
 my $all = shift @_;

 my $all_sketches = ($sketch eq 'all');

 $all = 1 if ($options{params} && $options{params} eq 'all');

 my $activations = load_json($options{'act-file'}, 1);

 if ($all_sketches)
 {
  $activations = {};
  print "Deactivated: all sketch activations!\n" unless $quiet;
 }
 elsif ($all)
 {
  my %info = %{$activations->{$sketch}};
  delete $activations->{$sketch};
  print "Deactivated: all $sketch activations (@{[ sort keys %info ]})\n"
   unless $quiet;
 }
 else
 {
  die "Can't deactivate sketch $sketch without --params"
   unless $options{params};

  die "Couldn't deactivate sketch $sketch: no activation for $options{params}"
   unless exists $activations->{$sketch}->{$options{params}};

  delete $activations->{$sketch}->{$options{params}};

  delete $activations->{$sketch} unless scalar keys %{$activations->{$sketch}};

  print "Deactivated: $sketch params $options{params}\n" unless $quiet;
 }

 ensure_dir(dirname($options{'act-file'}));
 open(my $ach, '>', $options{'act-file'})
  or die "Could not write activation file $options{'act-file'}: $!";

 print $ach $coder->encode($activations);
 close $ach;
}

sub remove
{
 my $toremove = shift @_;

 foreach my $repo (@{$options{repolist}})
 {
  next unless is_resource_local($repo);

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
    deactivate($sketch, 1);             # deactivate all the activations
    print "Successfully removed $sketch from $data->{dir}\n" unless $quiet;
   }
   else
   {
    print "Could not remove $sketch from $data->{dir}\n" unless $quiet;
   }
  }
 }
}

sub install
{
 my $sketches = shift @_;

 my $dest_repo = $options{'install-target'};
 push @{$options{repolist}}, $dest_repo unless grep { $_ eq $dest_repo } @{$options{repolist}};

 die "Can't install: no install target supplied!"
  unless defined $dest_repo;

 my $source = $options{'install-source'};
 my $base_dir = dirname($source);
 my $local = is_resource_local($source);

 print "Loading cf-sketch inventory from $source\n" if $verbose;

 my $search = search_internal($source, $sketches);
 my %known = %{$search->{known}};
 my %todo = %{$search->{todo}};

 foreach my $sketch (sort keys %todo)
 {
 print "Installing $sketch\n" unless $quiet;
  my $dir = $local ? File::Spec->catdir($base_dir, $todo{$sketch}) : "$base_dir/$todo{$sketch}";

  # make sure we only work with absolute directories
  my $data = load_sketch($local ? File::Spec->rel2abs($dir) : $dir);

  die "Sorry, but sketch $sketch could not be loaded from $dir!"
   unless $data;

  my %missing = map { $_ => 1 } missing_dependencies($data->{metadata}->{depends});

  # note that this will NOT catch circular dependencies!
  foreach my $missing (keys %missing)
  {
   print "Trying to find $missing dependency\n" unless $quiet;

   if (exists $todo{$missing})
   {
    print "$missing dependency is to be installed or was installed already\n"
     unless $quiet;
    delete $missing{$missing};
   }
   elsif (exists $known{$missing})
   {
    print "Found $missing dependency, trying to install it\n" unless $quiet;
    install([$missing]);
    delete $missing{$missing};
    $todo{$missing} = $known{$missing};
   }
  }

  my @missing = sort keys %missing;
  if (scalar @missing)
  {
   if ($options{force})
   {
    warn "Installing $sketch despite unsatisfied dependencies @missing"
     unless $quiet;
   }
   else
   {
    die "Can't install: $sketch has unsatisfied dependencies @missing";
   }
  }

  printf("Installing %s (%s) into %s\n",
         $sketch,
         $data->{file},
         $dest_repo)
   if $verbose;

  my $install_dir = File::Spec->catdir($dest_repo,
                                       split('::', $sketch));

  if (ensure_dir($install_dir))
  {
   print "Created destination directory $install_dir\n" if $verbose;
   foreach my $file (SKETCH_DEF_FILE, sort keys %{$data->{manifest}})
   {
    my $file_spec = $data->{manifest}->{$file};
    # build a locally valid install path, while the manifest can use / separator
    my $source = is_resource_local($data->{dir}) ? File::Spec->catfile($data->{dir}, split('/', $file)) : "$data->{dir}/$file";
    my $dest = File::Spec->catfile($install_dir, split('/', $file));

    my $dest_dir = dirname($dest);
    die "Could not make destination directory $dest_dir"
     unless ensure_dir($dest_dir);

    my $changed = 1;

    # TODO: maybe disable this?  It can be expensive for large files.
    if (!$options{force} &&
        is_resource_local($data->{dir}) &&
        compare($source, $dest) == 0)
    {
     warn "Manifest member $file is already installed in $dest"
      if $verbose;
     $changed = 0;
    }

    if ($changed)
    {
     if (is_resource_local($data->{dir}))
     {
      copy($source, $dest) or die "Aborting: copy $source -> $dest failed: $!";
     }
     else
     {
      my $rc = getstore($source, $dest);
      die "Aborting: remote copy $source -> $dest failed: error code $rc"
       unless is_success($rc)
      }
    }

    chmod oct($file_spec->{perm}), $dest if exists $file_spec->{perm};

    if (exists $file_spec->{user})
    {
     # TODO: ensure this works on platforms without getpwnam
     # TODO: maybe add group support too
     my ($login,$pass,$uid,$gid) = getpwnam($file_spec->{user})
      or die "$file_spec->{user} not in passwd file";

     chown $uid, $gid, $dest;
    }

    print "Installed file: $source -> $dest\n" if $changed && !$quiet;
   }

   print "Done installing $sketch\n" unless $quiet;
  }
  else
  {
   warn "Could not make install directory $install_dir, skipping $sketch";
  }
 }
}

# TODO: need functions for: test

sub missing_dependencies
{
 my $deps = shift @_;
 my @missing;

 my %tocheck = %$deps;

 foreach my $repo (@{$options{repolist}})
 {
  my $contents = repo_get_contents($repo);
  foreach my $dep (sort keys %tocheck)
  {
   if ($dep eq 'os' &&
       ref $tocheck{$dep} eq 'ARRAY')
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

    foreach my $os (sort @{$tocheck{$dep}})
    {
     if ($uname =~ m/$os/i)
     {
      print "Satisfied OS dependency: $uname matched $os\n"
       if $verbose;

      delete $tocheck{$dep};
     }
    }

    if (exists $tocheck{$dep})
    {
     print "Unsatisfied OS dependencies: $uname did not match [@{$deps->{$dep}}]\n"
      if $verbose;
    }
   }
   elsif ($dep eq 'cfengine' &&
          ref $tocheck{$dep} eq 'HASH' &&
          exists $tocheck{$dep}->{version})
   {
    my $version = cfengine_version();
    if ($version ge $tocheck{$dep}->{version})
    {
     print "Satisfied cfengine version dependency: $version present, needed ",
      $tocheck{$dep}->{version}, "\n"
       if $verbose;

     delete $tocheck{$dep};
    }
    else
    {
     print "Unsatisfied cfengine version dependency: $version present, need ",
      $tocheck{$dep}->{version}, "\n"
       if $verbose;
    }
   }
   elsif (exists $contents->{$dep})
   {
    my $dd = $contents->{$dep};
    # either the version is not specified or it has to match
    if (!exists $tocheck{$dep}->{version} ||
        $dd->{metadata}->{version} >= $tocheck{$dep}->{version})
    {
     print "Found dependency $dep in $repo\n" if $verbose;
     # TODO: test recursive dependencies, right now this will loop
     # TODO: maybe use a CPAN graph module
     push @missing, missing_dependencies($dd->{metadata}->{depends});
     delete $tocheck{$dep};
    }
    else
    {
     print "Found dependency $dep in $repo but the version doesn't match\n"
      if $verbose;
    }
   }
  }
 }

 push @missing, sort keys %tocheck;
 if (scalar @missing)
 {
  print "Unsatisfied dependencies: @missing\n" unless $quiet;
 }

 return @missing;
}

sub collect_dependencies
{
 my $deps = shift @_;

 my @collected;

 foreach my $repo (@{$options{repolist}})
 {
  my $contents = repo_get_contents($repo);
  foreach my $dep (sort keys %$deps)
  {
   if ($dep eq 'os' || $dep eq 'cfengine')
   {
   }
   elsif (exists $contents->{$dep})
   {
    my $dd = $contents->{$dep};
    # either the version is not specified or it has to match
    if (!exists $deps->{$dep}->{version} ||
        $dd->{metadata}->{version} >= $deps->{$dep}->{version})
    {
     print "Found dependency $dep in $repo\n" if $verbose;
     # TODO: test recursive dependencies, right now this will loop
     # TODO: maybe use a CPAN graph module
     push @collected, $dep, collect_dependencies($dd->{metadata}->{depends});
    }
    else
    {
     print "Found dependency $dep in $repo but the version doesn't match\n"
      if $verbose;
    }
   }
  }
 }

 return @collected;
}

sub find_remote_sketches
{
 my @urls = @_;
 my %contents;

 foreach my $repo (@urls)
 {
  my $sketches_url = "$repo/cfsketches";
  my $sketches = get($sketches_url)
   or die "Unable to retrieve $sketches_url : $!\n";

  foreach my $sketch_dir ($sketches =~ /(.+)/mg)
  {
   my $info = load_sketch("$repo/$sketch_dir");
   next unless $info;
   $contents{$info->{metadata}->{name}} = $info;
  }
 }

 return \%contents;
}

sub find_sketches
{
 my @dirs = @_;
 my %contents;

 @dirs = grep { -r $_ && -x $_ } @dirs;

 if (scalar @dirs)
 {
  find(sub
       {
        my $f = $_;
        if ($f eq SKETCH_DEF_FILE)
        {
         my $info = load_sketch($File::Find::dir);
         return unless $info;
         $contents{$info->{metadata}->{name}} = $info;
        }
       }, @dirs);
 }

 return \%contents;
}

sub load_sketch
{
 my $dir = shift @_;
 my $name = is_resource_local($dir) ? File::Spec->catfile($dir, SKETCH_DEF_FILE) : "$dir/" . SKETCH_DEF_FILE;
 my $json = load_json($name);

 my $info = {};
 my @messages;

 # stage 1: the data must be valid and a hash
 unless (defined $json && ref $json eq 'HASH')
 {
  push @messages, "Invalid JSON data";
 }

 # stage 2: check top-level manifest and metadata keys
 unless (scalar @messages)
 {
  # the manifest must be a hash
  push @messages, "Invalid manifest" unless (exists $json->{manifest} && ref $json->{manifest} eq 'HASH');
   
  # the metadata must be a hash
  push @messages, "Invalid metadata" unless (exists $json->{metadata} && ref $json->{metadata} eq 'HASH');
  
  # the interface must be an array
  push @messages, "Invalid interface" unless (exists $json->{interface} && ref $json->{interface} eq 'ARRAY');
 }

 # stage 3: check metadata details
 unless (scalar @messages)
 {
  # need a 'depends' key that points to a hash
  push @messages, "Invalid dependencies structure" unless (exists $json->{metadata}->{depends}  &&
                                                           ref $json->{metadata}->{depends}  eq 'HASH');

  foreach my $scalar (qw/name version license/)
  {
   push @messages, "Missing or undefined metadata element $scalar" unless $json->{metadata}->{$scalar};
  }
  
  foreach my $array (qw/authors portfolio/)
  {
   push @messages, "Missing, invalid, or undefined metadata array $array" unless ($json->{metadata}->{$array} &&
                                                                                  ref $json->{metadata}->{$array} eq 'ARRAY');
  }

  unless (scalar @messages)
  {
   push @messages, "Portfolio metadata can't be empty" unless scalar @{$json->{metadata}->{portfolio}};
  }
 }

 # stage 4: check entry_point and interface
 unless (scalar @messages)
 {
  push @messages, "Missing entry_point" unless exists $json->{entry_point};
 }
  
 # entry_point has to point to a file in the manifest or be null
 unless (scalar @messages || !defined $json->{entry_point})
 {
  push @messages, "entry_point $json->{entry_point} not in manifest"
   unless exists $json->{manifest}->{$json->{entry_point}};
 }
     
 # we should not have any interface files that do NOT exist in the manifest
 unless (scalar @messages)
 {
  foreach (@{$json->{interface}})
  {
   push @messages, "interface file $_ not in manifest" unless exists $json->{manifest}->{$_};
  }
 }

 if (!scalar @messages) # there are no errors, so go on...
 {
  my $name = $json->{metadata}->{name};
  $json->{dir} = $dir;
  $json->{file} = $name;

  if (verify_entry_point($name,
                         $dir,
                         $json->{manifest},
                         $json->{entry_point},
                         $json->{interface})) {
   # note this name will be stringified even if it's not a string
   return $json;
  }
  else
  {
   warn "Could not verify bundle entry point from $name" unless $quiet;
  }
 }
 else
 {
  warn "Could not load sketch definition from $name: [@{[join '; ', @messages]}]" unless $quiet;
 }

 return undef;
}

# sub make_packages
# {
#  my $todo = shift @_;

#  my @dirs;

#  find(sub
#       {
#        my $f = $_;
#        if ($f =~ m/readme/i &&
#            read_yes_no(sprintf("Use directory %s (interesting file %s)?",
#                                $File::Find::dir,
#                                $File::Find::name),
#                        'n'))
#        {
#         push @dirs, $File::Find::dir;
#         $File::Find::prune = 1;
#        }
#       }, @$todo);

#       die "@dirs";
# }

sub verify_entry_point
{
 my $name      = shift @_;
 my $dir       = shift @_;
 my $mft       = shift @_;
 my $entry     = shift @_;
 my $interface = shift @_;

 unless (defined $entry && defined $interface)
 {
  return {
          confirmed => 1,
          varlist => { activated => 'context' },
          optional_varlist => { },
         };
 }

 my $maincf = $entry;

 my $maincf_filename = is_resource_local($dir) ? File::Spec->catfile($dir, $maincf) : "$dir/$maincf";

 my @mcf;
 if (exists $mft->{$maincf})
 {
  if (is_resource_local($dir))
  {
   unless (-f $maincf_filename)
   {
    warn "Could not find sketch $name entry point '$maincf'" unless $quiet;
    return 0;
   }

   my $mcf;
   unless (open($mcf, '<', $maincf_filename) && $mcf)
   {
    warn "Could not open $maincf_filename: $!" unless $quiet;
    return 0;
   }
   @mcf = <$mcf>;
  }
  else
  {
   my $mcf = get($maincf_filename);
   unless ($mcf)
   {
    warn "Could not retrieve $maincf_filename: $!" unless $quiet;
    return 0;
   }

   @mcf = split "\n", $mcf;
  }
 }

 if (scalar @mcf)
 {
  $. = 0;
  my $bundle;
  my $meta = {
              confirmed        => 0,
              varlist          => { activated => 'context' },
              optional_varlist => { },
              default          => {},
             };

  while (defined(my $line = shift @mcf))
  {
   $.++;
   # TODO: need better cfengine parser; this should be extracted by cf-promises
   # when the meta: section is available.  It's very primitive now.

   if (defined $bundle && $line =~ m/^\s*bundle\s+agent\s+meta_$bundle/)
   {
    $meta->{confirmed} = 1;
   }

   # match "argument[foo]" string => "string";
   # or    "argument[bar]" string => "slist";
   # or    "argument[bar]" string => "context";
   # or    "argument[bar]" string => "array";
   if ($meta->{confirmed} &&
       $line =~ m/^\s*
                  "argument\[([^]]+)\]"
                  \s+
                  string
                  \s+=>\s+
                  "(context|string|slist|array)"\s*;/x)
   {
    $meta->{varlist}->{$1} = $2;
   }

   # match "optional_argument[foo]" string => "string";
   # or    "optional_argument[bar]" string => "slist";
   # or    "optional_argument[bar]" string => "context";
   # or    "optional_argument[bar]" string => "array";
   if ($meta->{confirmed} &&
       $line =~ m/^\s*
                  "optional_argument\[([^]]+)\]"
                  \s+
                  string
                  \s+=>\s+
                  "(context|string|slist|array)"\s*;/x)
   {
    $meta->{optional_varlist}->{$1} = $2;
   }

   # match "default[foo]" string => "string";
   # match "default[foo]" slist => { "a", "b", "c" };
   if ($meta->{confirmed} &&
       $line =~ m/^\s*
                  "default\[([^]]+)\]"
                  \s+
                  (string|slist)
                  \s+=>\s+
                  (.*)\s*;/x &&
      (exists $meta->{optional_varlist}->{$1} ||
       exists $meta->{varlist}->{$1}))
   {
    my $k = $1;
    my $type = $2;
    my $v = $3;

    # primitive extractor of slist values
    if ($type eq 'slist')
    {
     $v = [ ($v =~ m/"([^"]+)"/g) ];
    }
    # remove quotes from string values
    if ($type eq 'string')
    {
     $v =~ s/^["'](.*)["']$/$1/;
    }


    $meta->{default}->{$k} = $v;
   }

   # match "default[foo][bar]" string => "moo";
   if ($meta->{confirmed} &&
       $line =~ m/^\s*
                  "default\[([^]]+)\]\[([^]]+)\]"
                  \s+
                  (string)
                  \s+=>\s+
                  \"(.*)\"\s*;/x &&
      (exists $meta->{optional_varlist}->{$1} ||
       exists $meta->{varlist}->{$1} &&
       $meta->{varlist}->{$1} eq 'array'))
   {
    my $k = $1;
    my $array_k = $2;
    my $array_v = $4;

    $meta->{default}->{$k}->{$array_k} = $array_v;
   }

   if ($meta->{confirmed} && $line =~ m/^\s*\}\s*/)
   {
    return $meta;
   }

   if ($line =~ m/^\s*bundle\s+agent\s+(\w+)/ && $1 !~ m/^meta/)
   {
    $meta->{bundle} = $bundle = $1;
    print "Found definition of bundle $bundle at $maincf_filename:$.\n"
     if $verbose;
   }
  }

  if ($meta->{confirmed})
  {
   warn "Couldn't find the closing } for [$bundle] in $maincf_filename"
    unless $quiet;
  }
  elsif (defined $bundle)
  {
   warn "Couldn't find the meta definition of [$bundle] in $maincf_filename"
    unless $quiet;
  }
  else
  {
   warn "Couldn't find a usable bundle in $maincf_filename" unless $quiet;
  }

  return undef;
 }
}

sub is_resource_local
{
 my $resource = shift @_;
 return ($resource !~ m,^[a-z][a-z]+:,);
}

sub get_local_repo
{
 my $repo;
 foreach my $target (@{$options{repolist}})
 {
  if (is_resource_local($target))
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

  my $contents;
  if (is_resource_local($repo))
  {
   $contents = find_sketches($repo);
   $content_cache{$repo} = $contents;
  }
  else
  {
   $contents = find_remote_sketches($repo);
   $content_cache{$repo} = $contents;
  }

  return $contents;
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
 my $local_quiet = shift @_;

 my @j;

 if (is_resource_local($f))
 {
  my $j;
  unless (open($j, '<', $f) && $j)
  {
   warn "Could not inspect $f: $!" unless ($quiet || $local_quiet);
   return;
  }

  @j = <$j>;
 }
 else
 {
  my $j = get($f)
   or die "Unable to retrieve $f";

  @j = split "\n", $j;
 }

 if (scalar @j)
 {
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
      if (is_resource_local($f)) {
        $include = File::Spec->catfile(dirname($f), $include);
      }
      else {
        $include = dirname($f)."/$include";
      }
    }

    print "Including $include\n" unless $quiet;
    my $parent = load_json($include);
    if (ref $parent eq 'HASH')
    {
     $ret->{$_} = $parent->{$_} foreach keys %$parent;
    }
    else
    {
     warn "Malformed include contents from $include: not a hash" unless $quiet;
    }
   }
   delete $ret->{include};
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

sub cfengine_version
{
 my $cfv = `$options{cfhome}/cf-promises -V`; # TODO: get this from cfengine?
 if ($cfv =~ m/\s+(\d+\.\d+\.\d+)/)
 {
  return $1;
 }
 else
 {
  print "Unsatisfied cfengine dependency: could not get version from [$cfv].\n"
   if $verbose;
  return 0;
 }
}

sub local_cfsketches_source
{
 my $rootdir   = File::Spec->rootdir();
 my $dir       = Cwd::realpath(shift @_);
 my $inventory = File::Spec->catfile($dir, 'cfsketches');

 return $inventory if -f $inventory;

 # as we go up the tree, check for 'sketches/cfsketches' as well (so we don't crawl the whole file tree)
 my $sketches_probe = File::Spec->catfile($dir, 'sketches', 'cfsketches');
 return $sketches_probe if -f $sketches_probe;

 return undef if $rootdir eq $dir;
 my $updir = Cwd::realpath(dirname($dir));

 return local_cfsketches_source($updir);
}

sub make_runfile
{
 my $activations = shift @_;
 my $inputs      = shift @_;

 my $template = get_run_template();

 my $contexts = '';
 my $vars     = '';
 my $methods  = '';

 foreach my $a (keys %$activations)
 {
  foreach my $context (sort keys %{$activations->{$a}->{contexts}})
  {
   $contexts .= sprintf('      "_%s_%s" expression => "%sany";' . "\n",
                        $a,
                        $context,
                        $activations->{$a}->{contexts}->{$context} ? '' : '!')
  }

  $vars .= "       # string and slist variables for activation $a\n";

  foreach my $var (sort keys %{$activations->{$a}->{vars}})
  {
   $vars .= sprintf('       "_%s_%s" %s => %s;' . "\n",
                    $a,
                    $var,
                    $activations->{$a}->{vars}->{$var}->{type},
                    $activations->{$a}->{vars}->{$var}->{value});
  }

  $vars .= "       # array variables for activation $a\n";
  foreach my $avar (sort keys %{$activations->{$a}->{array_vars}})
  {
   foreach my $ak (sort keys %{$activations->{$a}->{array_vars}->{$avar}})
   {
    $vars .= sprintf('       "_%s_%s[%s]" string => "%s";' . "\n",
                     $a,
                     $avar,
                     $ak,
                     $activations->{$a}->{array_vars}->{$avar}->{$ak});
   }
  }

  $methods .= sprintf('    _%s_%s__activated::' . "\n",
                      $a,
                      $activations->{$a}->{prefix});
  $methods .= sprintf('      "%s %s %s" usebundle => %s("cfsketch_g._%s_%s__");' . "\n",
                      $a,
                      $activations->{$a}->{sketch},
                      $activations->{$a}->{params},
                      $activations->{$a}->{entry_bundle},
                      $a,
                      $activations->{$a}->{prefix});
 }

 $template =~ s/__INPUTS__/$inputs/g;
 $template =~ s/__CONTEXTS__/$contexts/g;
 $template =~ s/__VARS__/$vars/g;
 $template =~ s/__METHODS__/$methods/g;

 return $template;
}

sub get_run_template
{
 return <<'EOT';
body common control
{
      bundlesequence => { "cfsketch_run" };
      inputs => { __INPUTS__ };
}

bundle common cfsketch_g
{
  classes:
      # contexts
__CONTEXTS__
  vars:
__VARS__
}

bundle agent cfsketch_run
{
  methods:
      "cfsketch_g" usebundle => "cfsketch_g";
__METHODS__
}
EOT
}

sub tersedump
{
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Indent = 0;
  return Dumper(shift);
}

__DATA__

Help for cf-sketch

See README.md
