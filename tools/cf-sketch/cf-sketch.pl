#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use warnings;
use strict;
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
use LWP::Protocol::https;
use Term::ANSIColor qw(:constants);

$Term::ANSIColor::AUTORESET = 1;

my $coder;
my $canonical_coder;

# These turn AUTORESET off temporarily so that the "at ... line xxx"
# added automatically by Perl is also colorized.
sub color_warn {
  local $Term::ANSIColor::AUTORESET = 0;
  warn YELLOW @_;
  print RESET;
}
sub color_die {
  local $Term::ANSIColor::AUTORESET = 0;
  die RED @_;
}

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
     color_warn "Falling back to plain JSON module (you should install JSON::XS)";
     require JSON;
     $coder = JSON->new()->relaxed()->utf8()->allow_nonref();
     # for storing JSON data so it's directly comparable
     $canonical_coder = JSON->new()->canonical()->utf8()->allow_nonref();
    }
}

###### Some basic constants and settings.

use constant SKETCH_DEF_FILE => 'sketch.json';

# Inputs directory depending on root/non-root/policy hub
my $happy_root = $> != 0 ? glob("~/.cfagent/inputs") : (-e '/var/cfengine/state/am_policy_hub' ? '/var/cfengine/masterfiles' : '/var/cfengine/inputs');
# Configuration directory depending on root/non-root
my $configdir = $> == 0 ? '/etc/cf-sketch' : glob('~/.cf-sketch');

$| = 1;                         # autoflush


######

my %options = ();

# Default values
# Color enabled by default if STDOUT is connected to a tty (i.e. not redirected or piped somewhere).
my $color = -t STDOUT;
my %def_options =
 (
  verbose    => 0,
  quiet      => 0,
  help       => 0,
  force      => 0,
  fullpath   => 0,
  'dry-run'  => 0,
  # switched depending on root or non-root
  'act-file'   => "$configdir/activations.conf",
  configfile => "$configdir/cf-sketch.conf",
  'install-target' => File::Spec->catfile($happy_root, 'sketches'),
  'install-source' => local_cfsketches_source(File::Spec->curdir()) || 'https://raw.github.com/cfengine/design-center/master/sketches/cfsketches',
  'make-package' => [],
  params => {},
  cfpath => join (':', uniq(split(':', $ENV{PATH}||''), '/var/cfengine/bin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin')),
  runfile => File::Spec->catfile($happy_root, 'cf-sketch-runfile.cf'),
  standalone => 1,
  repolist => [ File::Spec->catfile($happy_root, 'sketches') ],
  color => $color,
 );

# This list contains both the help information and the command-line
# argument specifications. It is stored as a list so that order can
# be preserved when printing the help message.
# Format for each pair is "argspec", "Help text|argname"
# argspec is a Getopt::Long-style argument specification.
# "Help text" is the text that will be printed in the help message
# for this option. For options that take an argument, its human-
# readable description should be given at the end as "|argname",
# it will be automatically printed in the help message
# (so that the help reads "--search regex" and not
# just "--search string", for example).
# If argspec starts with three dashes, it is ignored as an
# argument spec, and the text will simply be printed in the
# help output.
my @options_desc =
 (
  "---", "Usage: $0 verb [verb-argument] [options]",
  "---", "\nVerbs:\n",
  "search|s=s@",               "Search sketch repository, use 'all' to show everything.|regex",
  "list|l:s@",                 "Search list of installed sketches, use 'all' or no argument to show everything.|[regex]",
  "list-activations|la",       "List activated sketches, including their activation parameters.",
  "install|i=s@",              "Install or update the given sketch.|sketch",
  "activate|a=s%",             "Activate the given sketch with the given JSON parameters file.|sketch=paramfile",
  "deactivate|d=s@",           "Deactivate sketches by number, as shown by --list-activations, or by name (regular expression).|n",
  "deactivate-all|da",         "Deactivate all sketches.",
  "remove|r=s@",               "Remove given sketch.|sketch",
  "api=s",                     "Show the API (required/optional parameters) of the given sketch.|sketch",
  "generate|g",                "Generate CFEngine runfile to execute activated sketches.",
  "fullpath|fp",               "Use full paths in the CFEngine runfile (off by default)",
  "save-config|config-save",   "Save configuration parameters so that they are automatically loaded in the future.",
  "metarun=s",                 "Load and execute a metarun file of the form { options => \%options }, which indicates the entire behavior for this run.|file",
  "save-metarun=s",            "Save the parameters and actions of the current execution to the named file, for future use with --metarun.|file",

  "---", "\nOptions:\n",
  "quiet|q",                   "Supress non-essential output.",
  "verbose|v",                 "Produce additional output.",
  "dryrun|n",                  "Do not do anything, just indicate what would be done.",
  "help",                      "This help message.",
  "color!",                    "Colorize output, enabled by default if running on a terminal.",
  "params|p=s%",               "With --activate, override certain parameter values.|param=value",
  "force|f",                   "Ignore dependency/OS/architecture checks. Use with --install and --activate.",
  "cfpath=s",                  "Where to look for CFEngine binaries. Default: $def_options{cfpath}.",
  "configfile|cf=s",           "Configuration file to use. Default: $def_options{configfile}.|file",
  "runfile|rf=s",              "Where --generate will store the runfile. Default: $def_options{runfile}.|file",
  "act-file|af=s",             "Where the information about activated sketches will be stored. Default: $def_options{'act-file'}.|file",
  "install-target|it=s",       "Where sketches will be installed. Default: $def_options{'install-target'}.|dir",
  "json",                      "With --api, produce output in JSON format instead of human-readable format.",
  "standalone|st!",            "With --generate, produce a standalone file (including body common control). Enabled by default, negate with --no-standalone.",
  "install-source|is=s",       "Location (file path or URL) of a cfsketches catalog file that contains the list of sketches available for installation. Default: $def_options{'install-source'}.|loc",
  "repolist|rl=s@",            "Comma-separated list of local directories to search for installed sketches for activation, deactivation, removal, or runfile generation. Default: ".join(', ', @{$def_options{repolist}}).".|dirs",
  # "make-package=s@",
#  "test|t=s@",
  "---", "\nPlease see https://github.com/cfengine/design-center/wiki for the full cf-sketch documentation.",
 );

# Convert to hash so we can extract keys for @options_spec
my %options_desc = @options_desc;
# Extract just the keys, minus the internal formatting-related elements
my @options_spec = grep(!/^---/, keys %options_desc);

# Options given on the command line
my %cmd_options;
GetOptions (
            \%cmd_options,
            @options_spec,
           );

# Disable color if needed
unless ((exists($cmd_options{color}) && $cmd_options{color}) || (!exists($cmd_options{color}) && $def_options{color})) {
    $ENV{ANSI_COLORS_DISABLED}=1;
}

if ($cmd_options{help})
{
 print_help();
 exit;
}

my $metarun = $cmd_options{metarun};

if ($metarun)
{
 if (open(my $mfh, '<', $metarun))
 {
  # slurp the entire file
  my $jsontxt = join("", <$mfh>);
  my $meta = $coder->decode($jsontxt);

  color_die "Malformed metarun file: no 'options' key"
   unless exists $meta->{options};

  %options = %{$meta->{options}};
 }
 else
 {
  color_die "Could not load metarun file $metarun: $!";
 }
}
else
{
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
}

my $required_version = '3.3.0';
my $version = cfengine_version();

if (!$options{force} && $required_version gt $version)
{
 color_die "Couldn't ensure CFEngine version [$version] is above required [$required_version], sorry!";
}

# Allow both comma-separated values and multiple occurrences of --repolist
$options{repolist} = [ split(/,/, join(',', @{$options{repolist}})) ];

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
my $dryrun  = $options{'dry-run'};

print "Full configuration: ", $coder->encode(\%options), "\n" if $verbose;

my $save_metarun = delete $options{'save-metarun'};
if ($save_metarun)
{
 maybe_ensure_dir(dirname($save_metarun));
 maybe_write_file($save_metarun,
                  'metarun file',
                  $coder->pretty(1)->encode({ options => \%options }));
 print GREEN "Saved metarun file $save_metarun\n";
 exit;
}

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
 color_die "Can't load any activations from $options{'act-file'}"
  unless defined $activations && ref $activations eq 'HASH';

 my $activation_id = 1;
 foreach my $sketch (sort keys %$activations)
 {
  if ('HASH' eq ref $activations->{$sketch})
  {
   color_warn "Skipping unusable activations for sketch $sketch!";
   next;
  }

  foreach my $activation (@{$activations->{$sketch}})
  {
   print BOLD GREEN."$activation_id\t".YELLOW."$sketch".RESET,
    $coder->encode($activation),
     "\n";

   $activation_id++;
  }
 }
 exit;
}

if ($options{'deactivate-all'})
{
 $options{deactivate} = '.*';
}

my @nonterminal = qw/deactivate remove install activate generate/;
my @terminal = qw/test api search/;
my @callable = (@nonterminal, @terminal);

foreach my $word (@callable)
{
 if ($options{$word})
 {
  # TODO: hack to replace a method table, eliminate
  no strict 'refs';
  $word->($options{$word});
  use strict 'refs';

  # exit unless the command was non-terminal...
  exit unless grep { $_ eq $word } @nonterminal;
 }
}

# now exit if any non-terminal commands were specified
exit if grep { $options{$_} } @nonterminal;

push @callable, 'list', 'save-config';
color_die "Sorry, I don't know what you want to do.  You have to specify a valid verb. Run $0 --help to see the complete list.\n";

sub configure_self
{
 my $cf    = shift @_;

 my %keys = (
             'repolist' => 1,             # array
             'cfpath'   => 0,             # string
             'install-source' => 0,
             'install-target' => 0,
             'act-file' => 0,
             'runfile' => 0,
            );

 print "Saving configuration keys [@{[sort keys %keys]}] to file $cf\n" unless $quiet;

 my %config;

 foreach my $key (sort keys %keys) {
   $config{$key} = $options{$key};
   print "Saving option $key=".tersedump($config{$key})."\n"
     if $verbose;
 }

 maybe_ensure_dir(dirname($cf));
 maybe_write_file($cf, 'configuration input', $coder->pretty(1)->encode(\%config));
}

sub search
{
 my $terms = shift @_;
 my $source = $options{'install-source'};
 my $base_dir = dirname($source);
 my $search = search_internal($source, []);
 my $local_dir = is_resource_local($base_dir);

 SKETCH:
 foreach my $sketch (sort keys %{$search->{known}})
 {
  my $dir = $local_dir ? File::Spec->catdir($base_dir, $search->{known}->{$sketch}) : "$base_dir/$search->{known}->{$sketch}";
  foreach my $term (@$terms)
  {
   if ($sketch =~ m/$term/ || $dir =~ m/$term/)
   {
    print GREEN, "$sketch", RESET, " $dir\n";
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
 my $local_dir = is_resource_local($source);

 if ($local_dir)
 {
  open(my $invf, '<', $source)
   or color_die "Could not open cf-sketch inventory file $source: $!";

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
   or color_die "Unable to retrieve $source : $!\n";

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

   print GREEN, "$sketch", RESET, " $contents->{$sketch}->{fulldir}\n";
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
   color_die "Can't load any activations from $options{'act-file'}"
    unless defined $activations && ref $activations eq 'HASH';

   my $activation_counter = 1;
   my $template_activations = {};
   my $standalone = $options{'standalone'};

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
      if ('HASH' eq ref $activations->{$sketch})
      {
       color_warn "Skipping unusable activations for sketch $sketch!\n";
       next;
      }

      my $activation_id = 1;
      foreach my $pdata (@{$activations->{$sketch}})
      {
       print "Loading activation $activation_id for sketch $sketch\n"
        if $verbose;
       color_die "Couldn't load activation params for $sketch: $!"
        unless defined $pdata;

       my $data = $contents->{$sketch};

       my %types;
       my %booleans;
       my %vars;

       my $entry_point = verify_entry_point($sketch,
                                            $data->{fulldir},
                                            $data->{manifest},
                                            $data->{entry_point},
                                            $data->{interface});

       color_die "Could not load the entry point definition of $sketch"
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
                         activation_id => $activation_id,
                         pdata  => $pdata,
                         sketch => $sketch,
                         prefix => $prefix,
                        };

       my $varlist = $entry_point->{varlist};

       # force-feed the bundle location here to work around a possible this.promise_filename bug
       $varlist->{bundle_home} = 'string';
       $pdata->{bundle_home} = '$(sys.workdir)/inputs/sketches/' . $data->{dir};

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

        color_die "Supplied augment variable for key $k is not an array"
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
         color_die "Unable to activate: provided value " .
          $coder->encode($v) . " for key $k is not an array"
           unless ref $v eq 'HASH';

         $activation->{array_vars}->{$cfengine_k} = $v;
         if ($augment_v)
         {
          $activation->{array_vars}->{$cfengine_k}->{$_} = $augment_v->{$_}
           foreach keys %$augment_v;
         }

         color_die "Sorry, but you can't activate with an empty list in $k"
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
       $template_activations->{$ak} = $activation; # the activation counter is 1..N globally!
       $activation_id++;        # the activation ID is 1..N per sketch
      }

      next ACTIVATION;
     }
    }
    color_die "Could not find sketch $sketch in repo list @{$options{repolist}}";
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
    color_die "Sorry, can't generate: unsatisfied dependencies [@deps]";
   }

   # process input template, substituting variables
   push @inputs, $template_activations->{$_}->{file}
    foreach sort keys %$template_activations;

   my $includes = join ', ', map { "\"$_\"" } uniq(@inputs);

   # maybe make the run template configurable?
   my $output = make_runfile($template_activations, $includes, $standalone);

   my $run_file = $options{runfile};

   maybe_write_file($run_file, 'run', $output);
   print GREEN "Generated ".($standalone?"standalone":"non-standalone")." run file $run_file\n"
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
                                        $data->{fulldir},
                                        $data->{manifest},
                                        $data->{entry_point},
                                        $data->{interface});

   if ($entry_point)
   {
     $found = 1;
     my @mandatory_args = sort keys %{$entry_point->{varlist}};
     my @optional_args = sort keys %{$entry_point->{optional_varlist}};
     local $Data::Dumper::Terse = 1;
     local $Data::Dumper::Indent = 0;
     my %defaults = map { $_ => Dumper($entry_point->{default}->{$_})} @optional_args;
     my %empty_values = ( 'context' => '',
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
       print GREEN "Sketch $sketch\n";
       if ($data->{entry_point}) {
         print BOLD BLUE."  Entry bundle name:".RESET." $entry_point->{bundle}\n";
         if (scalar @mandatory_args) {
           print BOLD BLUE "  Mandatory arguments:\n";
           foreach my $arg (@mandatory_args) {
             print "    ".BLUE."$arg:".RESET." $entry_point->{varlist}->{$arg}\n";
           }
         }
         else {
           print YELLOW "  No mandatory arguments.\n";
         }
         if (scalar @optional_args) {
           print BOLD BLUE "  Optional arguments:\n";
           foreach my $arg (@optional_args) {
             print "    ".BLUE."$arg:".RESET." $entry_point->{optional_varlist}->{$arg} (default value: $defaults{$arg})\n";
           }
         }
         else {
           print YELLOW "  No optional arguments.\n";
         }
       }
       else {
         print BOLD BLUE "  This is a library sketch - no entry point defined.\n";
       }
     }
   }
   else {
     color_die "I cannot find API information about $sketch.\n";
   }
 }
}
 unless ($found) {
   color_die "I could not find sketch $sketch. It doesn't seem to be installed.\n";
 }
}

sub activate
{
 my $aspec = shift @_;

 foreach my $sketch (sort keys %$aspec)
 {
  my $pfile = $aspec->{$sketch};

  print "Loading activation params from $pfile\n" unless $quiet;
  my $aparams = load_json($pfile);

  color_die "Could not load activation params from $pfile"
   unless ref $aparams eq 'HASH';

  foreach my $extra (sort keys %{$options{params}})
  {
   $aparams->{$extra} = $options{params}->{$extra};
   printf("Overriding aparams %s from the command line, value %s\n",
          $extra, $options{params}->{$extra})
    if $verbose;
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
                                         $data->{fulldir},
                                         $data->{manifest},
                                         $data->{entry_point},
                                         $data->{interface});

    if ($entry_point)
    {
     foreach my $default_k (keys %{$entry_point->{default}})
     {
      next if exists $aparams->{$default_k};
      $aparams->{$default_k} = $entry_point->{default}->{$default_k};
     }

     my $varlist = $entry_point->{varlist};
     foreach my $varname (sort keys %$varlist)
     {
      if ($varname eq 'activated' && ! exists $aparams->{$varname})
      {
       print "Inserting artificial 'activated' boolean set to 'any' so it's always true.\n"
        unless $quiet;
       $aparams->{$varname} = 'any';
      }

      color_die "Can't activate $sketch: its interface requires variable '$varname'"
       unless exists $aparams->{$varname};
      print "Satisfied by aparams: '$varname'\n" if $verbose;
     }

     $varlist = $entry_point->{optional_varlist};
     foreach my $varname (sort keys %$varlist)
     {
      next unless exists $aparams->{$varname};
      print "Optional satisfied by aparams: '$varname'\n" if $verbose;
     }
    }
    else
    {
     color_die "Can't activate $sketch: missing entry point in $data->{entry_point}"
    }

    # activation successful, now install it
    my $activations = load_json($options{'act-file'}, 1);

    if ('HASH' eq ref $activations->{$sketch})
    {
     color_warn "Ignoring old-style activations for sketch $sketch!";
     $activations->{$sketch} = [];
    }

    foreach my $check (@{$activations->{$sketch}})
    {
     my $p = $canonical_coder->encode($check);
     my $q = $canonical_coder->encode($aparams);
     if ($p eq $q)
     {
      if ($options{force})
      {
       color_warn "Activating duplicate parameters [$q] because of --force"
        unless $quiet;
      }
      else
      {
       color_die "Can't activate: $sketch has already been activated with $q";
      }
     }
    }

    push @{$activations->{$sketch}}, $aparams;
    my $activation_id = scalar @{$activations->{$sketch}};

    maybe_ensure_dir(dirname($options{'act-file'}));
    maybe_write_file($options{'act-file'}, 'activation', $coder->encode($activations));
    print GREEN "Activated: $sketch $activation_id aparams $pfile\n" unless $quiet;

    $installed = 1;
    last;
   }
  }

  color_die "Could not activate sketch $sketch, it was not in the given list of repositories [@{$options{repolist}}]"
   unless $installed;
 }
}

sub deactivate
{
 my $nums_or_name = shift @_;

 my $activations = load_json($options{'act-file'}, 1);
 my %modified;

 if ('' eq ref $nums_or_name)     # a string or regex
 {
  foreach my $sketch (sort keys %$activations)
  {
   next unless $sketch =~ m/$nums_or_name/;
   delete $activations->{$sketch};
   $modified{$sketch}++;
   print GREEN "Deactivated: all $sketch activations\n"
    unless $quiet;
  }
 }
 elsif ('ARRAY' eq ref $nums_or_name)
 {
  my @deactivations;

  my $offset = 1;
  foreach my $sketch (sort keys %$activations)
  {
   if ('HASH' eq ref $activations->{$sketch})
   {
    color_warn "Ignoring old-style activations for sketch $sketch!";
    $activations->{$sketch} = [];
    $modified{$sketch}++;
    print GREEN "Deactivated: all $sketch activations\n"
     unless $quiet;
   }

   my @new_activations;

   foreach my $activation (@{$activations->{$sketch}})
   {
    if (grep { $_ == $offset } @$nums_or_name)
    {
     $modified{$sketch}++;
     print GREEN "Deactivated: $sketch activation $offset\n" unless $quiet;
    }
    else
    {
     push @new_activations, $activation;
    }
    $offset++;
   }

   if (exists $modified{$sketch})
   {
    $activations->{$sketch} = \@new_activations;
   }
  }
 }
 else
 {
  color_die "Sorry, I can't handle parameters " . $coder->encode($nums_or_name);
 }

 if (scalar keys %modified)
 {
  maybe_ensure_dir(dirname($options{'act-file'}));
  maybe_write_file($options{'act-file'}, 'activation', $coder->encode($activations));
 }
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
    ($_ eq $sketch) || ($contents->{$_}->{dir} eq $sketch) || ($contents->{$_}->{fulldir} eq $sketch)
   } keys %$contents;

   unless (scalar @matches) {
     color_warn "I did not find an installed sketch that matches '$sketch' - not removing it.\n";
     next;
   }
   $sketch = shift @matches;
   my $data = $contents->{$sketch};
   if (maybe_remove_dir($data->{fulldir}))
   {
    deactivate($sketch);       # deactivate all the activations of the sketch
    print GREEN "Successfully removed $sketch from $data->{fulldir}\n" unless $quiet;
   }
   else
   {
    print RED "Could not remove $sketch from $data->{fulldir}\n" unless $quiet;
   }
  }
 }
}

sub install
{
 my $sketches = shift @_;

 my $dest_repo = $options{'install-target'};
 push @{$options{repolist}}, $dest_repo unless grep { $_ eq $dest_repo } @{$options{repolist}};

 color_die "Can't install: no install target supplied!"
  unless defined $dest_repo;

 my $source = $options{'install-source'};
 my $base_dir = dirname($source);
 my $local_dir = is_resource_local($source);

 print "Loading cf-sketch inventory from $source\n" if $verbose;

 my $search = search_internal($source, $sketches);
 my %known = %{$search->{known}};
 my %todo = %{$search->{todo}};

 foreach my $sketch (sort keys %todo)
 {
 print BLUE "Installing $sketch\n" unless $quiet;
  my $dir = $local_dir ? File::Spec->catdir($base_dir, $todo{$sketch}) : "$base_dir/$todo{$sketch}";

  # make sure we only work with absolute directories
  my $data = load_sketch($local_dir ? File::Spec->rel2abs($dir) : $dir);

  color_die "Sorry, but sketch $sketch could not be loaded from $dir!"
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
    color_warn "Installing $sketch despite unsatisfied dependencies @missing"
     unless $quiet;
   }
   else
   {
    color_die "Can't install: $sketch has unsatisfied dependencies @missing";
   }
  }

  printf("Installing %s (%s) into %s\n",
         $sketch,
         $data->{file},
         $dest_repo)
   if $verbose;

  my $install_dir = File::Spec->catdir($dest_repo,
                                       split('::', $sketch));

  if (maybe_ensure_dir($install_dir))
  {
   print "Created destination directory $install_dir\n" if $verbose;
   print "Checking and installing sketch files.\n" unless $quiet;
   my $anything_changed = 0;
   foreach my $file (SKETCH_DEF_FILE, sort keys %{$data->{manifest}})
   {
    my $file_spec = $data->{manifest}->{$file};
    # build a locally valid install path, while the manifest can use / separator
    my $source = is_resource_local($data->{dir}) ? File::Spec->catfile($data->{dir}, split('/', $file)) : "$data->{dir}/$file";
    my $dest = File::Spec->catfile($install_dir, split('/', $file));

    my $dest_dir = dirname($dest);
    color_die "Could not make destination directory $dest_dir"
     unless maybe_ensure_dir($dest_dir);

    my $changed = 1;

    # TODO: maybe disable this?  It can be expensive for large files.
    if (!$options{force} &&
        is_resource_local($data->{dir}) &&
        compare($source, $dest) == 0)
    {
     color_warn "  Manifest member $file is already installed in $dest"
      if $verbose;
     $changed = 0;
    }

    if ($changed)
    {
     if ($dryrun)
     {
      print YELLOW "  DRYRUN: skipping installation of $source to $dest\n";
     }
     else
     {
      if (is_resource_local($data->{dir}))
      {
       copy($source, $dest) or color_die "Aborting: copy $source -> $dest failed: $!";
      }
      else
      {
       my $rc = getstore($source, $dest);
       color_die "Aborting: remote copy $source -> $dest failed: error code $rc"
        unless is_success($rc)
      }
     }
    }

    if (exists $file_spec->{perm})
    {
     if ($dryrun)
     {
      print YELLOW "  DRYRUN: skipping chmod $file_spec->{perm} $dest\n";
     }
     else
     {
      chmod oct($file_spec->{perm}), $dest;
     }
    }

    if (exists $file_spec->{user})
    {
     # TODO: ensure this works on platforms without getpwnam
     # TODO: maybe add group support too
     my ($login,$pass,$uid,$gid) = getpwnam($file_spec->{user})
      or color_die "$file_spec->{user} not in passwd file";

     if ($dryrun)
     {
      print YELLOW "  DRYRUN: skipping chown $uid:$gid $dest\n";
     }
     else
     {
      chown $uid, $gid, $dest;
     }
    }

    print "  $source -> $dest\n" if $changed && $verbose;
    $anything_changed += $changed;
   }

   unless ($quiet) {
     if ($anything_changed) {
       print GREEN "Done installing $sketch\n";
     }
     else {
       print GREEN "Everything was up to date - nothing changed.\n";
     }
   }
  }
  else
  {
   color_warn "Could not make install directory $install_dir, skipping $sketch";
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
     print YELLOW "Unsatisfied OS dependencies: $uname did not match [@{$deps->{$dep}}]\n"
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
     print YELLOW "Unsatisfied cfengine version dependency: $version present, need ",
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
     print YELLOW "Found dependency $dep in $repo but the version doesn't match\n"
      if $verbose;
    }
   }
  }
 }

 push @missing, sort keys %tocheck;
 if (scalar @missing)
 {
  print YELLOW "Unsatisfied dependencies: @missing\n" unless $quiet;
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
     print YELLOW "Found dependency $dep in $repo but the version doesn't match\n"
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
   or color_die "Unable to retrieve $sketches_url : $!\n";

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
  foreach my $topdir (@dirs)
  {
   find(sub
        {
         my $f = $_;
         if ($f eq SKETCH_DEF_FILE)
         {
          my $info = load_sketch($File::Find::dir, $topdir);
          return unless $info;
          $contents{$info->{metadata}->{name}} = $info;
         }
        }, $topdir);
  }
 }

 return \%contents;
}

sub load_sketch
{
 my $dir    = shift @_;
 my $topdir = shift @_;

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
  $json->{dir} = $options{fullpath} ? $dir : File::Spec->abs2rel( $dir, $topdir );
  $json->{fulldir} = $dir;
  $json->{file} = $name;

  if (verify_entry_point($name,
                         $json->{fulldir},
                         $json->{manifest},
                         $json->{entry_point},
                         $json->{interface})) {
   # note this name will be stringified even if it's not a string
   return $json;
  }
  else
  {
   color_warn "Could not verify bundle entry point from $name" unless $quiet;
  }
 }
 else
 {
  color_warn "Could not load sketch definition from $name: [@{[join '; ', @messages]}]" unless $quiet;
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
    color_warn "Could not find sketch $name entry point '$maincf_filename'" unless $quiet;
    return 0;
   }

   my $mcf;
   unless (open($mcf, '<', $maincf_filename) && $mcf)
   {
    color_warn "Could not open $maincf_filename: $!" unless $quiet;
    return 0;
   }
   @mcf = <$mcf>;
  }
  else
  {
   my $mcf = get($maincf_filename);
   unless ($mcf)
   {
    color_warn "Could not retrieve $maincf_filename: $!" unless $quiet;
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
   # optionally with a comma instead of a semicolon at the end
   if ($meta->{confirmed} &&
       $line =~ m/^\s*
                  "argument\[([^]]+)\]"
                  \s+
                  string
                  \s+=>\s+
                  "(context|string|slist|array)"\s*[;,]/x)
   {
    $meta->{varlist}->{$1} = $2;
   }

   # match "optional_argument[foo]" string => "string";
   # or    "optional_argument[bar]" string => "slist";
   # or    "optional_argument[bar]" string => "context";
   # or    "optional_argument[bar]" string => "array";
   # optionally with a comma instead of a semicolon at the end
   if ($meta->{confirmed} &&
       $line =~ m/^\s*
                  "optional_argument\[([^]]+)\]"
                  \s+
                  string
                  \s+=>\s+
                  "(context|string|slist|array)"\s*[;,]/x)
   {
    $meta->{optional_varlist}->{$1} = $2;
   }

   # match "default[foo]" string => "string";
   # match "default[foo]" slist => { "a", "b", "c" };
   # optionally with a comma instead of a semicolon at the end
   if ($meta->{confirmed} &&
       $line =~ m/^\s*
                  "default\[([^]]+)\]"
                  \s+
                  (string|slist)
                  \s+=>\s+
                  (.*)\s*[;,]/x &&
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
   color_warn "Couldn't find the closing } for [$bundle] in $maincf_filename"
    unless $quiet;
  }
  elsif (defined $bundle)
  {
   color_warn "Couldn't find the meta definition of [$bundle] in $maincf_filename"
    unless $quiet;
  }
  else
  {
   color_warn "Couldn't find a usable bundle in $maincf_filename" unless $quiet;
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

sub uniq
{
  # Uniquify, preserving order
  my @result = ();
  my %seen = ();
  foreach (@_) {
    push @result, $_ unless exists($seen{$_});
    $seen{$_}=1;
  }
  return @result;
}

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
   color_warn "Could not inspect $f: $!" unless ($quiet || $local_quiet);
   return;
  }

  @j = <$j>;
 }
 else
 {
  my $j = get($f)
   or color_die "Unable to retrieve $f";

  @j = split "\n", $j;
 }

 if (scalar @j)
 {
  chomp @j;
  s/\n//g foreach @j;
  s/^\s*(#|\/\/).*//g foreach @j;
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
     color_warn "Malformed include contents from $include: not a hash" unless $quiet;
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

sub maybe_ensure_dir
{
   if ($dryrun)
   {
    print YELLOW "DRYRUN: will not ensure/create directory $_[0]\n";
    return 1;
   }

   return ensure_dir($_[0]);
}

sub maybe_remove_dir
{
   if ($dryrun)
   {
    print YELLOW "DRYRUN: will not remove directory $_[0]\n";
    return 1;
   }

   return remove_dir($_[0]);
}

sub maybe_write_file
{
 my $file = shift @_;
 my $desc = shift @_;
 my $data = shift @_;

 if ($dryrun)
 {
  print YELLOW "DRYRUN: will not write $desc file $file with data\n$data";
 }
 else
 {
  open(my $fh, '>', $file)
   or color_die "Could not write $desc file $file: $!";

  print $fh $data;
  close $fh;
 }
}


{
 my $promises_binary;
 sub cfengine_version
 {
  my $promises_name = 'cf-promises';

  unless ($promises_binary)
  {
   foreach my $check_path (split ':', $options{cfpath})
   {
    my $check = "$check_path/$promises_name";
    $promises_binary = $check if -x $check;
    last if $promises_binary;
   }
  }

  color_die "Sorry, but we couldn't find $promises_name in the search path $options{cfpath}.  Please set \$PATH or use the --cfpath parameter!"
   unless $promises_binary;

  print "Excellent, we found $promises_binary to interface with CFEngine\n"
   if $verbose;

  my $cfv = `$promises_binary -V`;     # TODO: get this from cfengine?
  if ($cfv =~ m/\s+(\d+\.\d+\.\d+)/)
  {
   return $1;
  }
  else
  {
   print YELLOW "Unsatisfied cfengine dependency: could not get version from [$cfv].\n"
    if $verbose;
   return 0;
  }
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

sub is_json_boolean
{
 return ((ref shift) =~ m/JSON.*Boolean/);
}

sub recurse_print
{
 my $ref             = shift @_;
 my $prefix          = shift @_;
 my $unquote_scalars = shift @_;

 my @print;
                      # $_->{path},
                      # $_->{type},
                      # $_->{value}) foreach @toprint;

 # recurse for hashes
 if (ref $ref eq 'HASH')
 {
  push @print, recurse_print($ref->{$_}, $prefix . "[$_]", $unquote_scalars)
   foreach sort keys %$ref;
 }
 elsif (ref $ref eq 'ARRAY')
 {
  push @print, {
                path => $prefix,
                type => 'slist',
                value => '{' . join(", ", map { "\"$_\"" } @$ref) . '}'
               };
 }
 else
 {
  # convert to a 1/0 boolean
  $ref = ! ! $ref if is_json_boolean($ref);
  push @print, {
                path => $prefix,
                type => 'string',
                value => $unquote_scalars ? $ref : "\"$ref\""
               };
 }

 return @print;
}

sub make_runfile
{
 my $activations = shift @_;
 my $inputs      = shift @_;
 my $standalone  = shift @_;

 my $template = get_run_template();

 my $contexts = '';
 my $vars     = '';
 my $methods  = '';
 my $commoncontrol = '';

 if ($standalone)
 {
  $commoncontrol=q(body common control
{
      bundlesequence => { "cfsketch_run" };
      inputs => { @(cfsketch_g.inputs) };
});
 }

 foreach my $a (keys %$activations)
 {
  $contexts .= "       # contexts for activation $a\n";
  foreach my $context (sort keys %{$activations->{$a}->{contexts}})
  {
   my $value = $activations->{$a}->{contexts}->{$context}->{value};
   my $print;

   if (ref $value eq '' && $value ne '0' && $value ne '1') # a string, not a boolean!
   {
    $print = $value;
   }
   else                                 # this will take a JSON boolean, or 0/1
   {
    $print = $value ? 'any' : '!any';
   }

   $contexts .= sprintf('      "_%s_%s" expression => "%s";' . "\n",
                        $a,
                        $context,
                        $print)
  }

  $vars .= "       # string versions of the contexts for activation $a\n";
  foreach my $context (sort keys %{$activations->{$a}->{contexts}})
  {
   my @context_hack = split '__', $context;
   my $short_context = pop @context_hack;
   my $context_prefix = join '__', @context_hack, '';

   $vars .= sprintf('      "_%s_%scontexts_text[%s]" string => "%s";' . "\n",
                    $a,
                    $context_prefix,
                    $short_context,
                    $activations->{$a}->{contexts}->{$context}->{value} ? 'ON' : 'OFF')
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
    my $av = $activations->{$a}->{array_vars}->{$avar}->{$ak};
    my @toprint = recurse_print($av, '');
    $vars .= sprintf('       "_%s_%s[%s]%s" %s => %s;' . "\n",
                      $a,
                      $avar,
                      $ak,
                      $_->{path},
                      $_->{type},
                      $_->{value}) foreach @toprint;
   }
  }

  $methods .= sprintf('    _%s_%s__activated::' . "\n",
                      $a,
                      $activations->{$a}->{prefix});
  $methods .= sprintf('      "%s %s %s" usebundle => %s("cfsketch_g._%s_%s__");' . "\n",
                      $a,
                      $activations->{$a}->{sketch},
                      $activations->{$a}->{activation_id},
                      $activations->{$a}->{entry_bundle},
                      $a,
                      $activations->{$a}->{prefix});
 }

 $template =~ s/__INPUTS__/$inputs/g;
 $template =~ s/__CONTEXTS__/$contexts/g;
 $template =~ s/__VARS__/$vars/g;
 $template =~ s/__METHODS__/$methods/g;
 $template =~ s/__COMMONCONTROL__/$commoncontrol/g;

 return $template;
}

sub get_run_template
{
 return <<'EOT';
__COMMONCONTROL__

bundle common cfsketch_g
{
  classes:
      # contexts
__CONTEXTS__
  vars:
       # Files that need to be loaded for this to work.
       "inputs" slist => { __INPUTS__ };

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

# Returns an indented string containing a list. Syntax is:
# _sprintlist($listref[, $firstline[, $separator[, $indent
#             [, $break[, $linelen[, $lineprefix]]]]])
# All lines are indented by $indent spaces (default
# 15). If $firstline is given, that string is inserted in the
# indentation of the first line (it is truncated to $indent spaces
# unless $break is true, in which case the list is pushed to the next
# line). Normally the list elements are separated by commas and spaces
# ", ". If $separator is given, that string is used as a separator.
# Lines are wrapped to $linelen characters, unless it is specified as
# some other value. A value of 0 for $linelen makes it not do line wrapping.
# If $lineprefix is given, it is printed at the beginning of each line.
sub _sprintlist {
  my ($listref, $fline, $separator, $indent, $break, $linelen, $lp) = @_;
  # Figure out default arguments
  my @list=@$listref;
  $separator ||= ", ";
  $indent = 15 unless defined($indent);
  my $space=" " x $indent;
  $fline ||= $space;
  $break ||= 0;
  $linelen ||= 80;
  $lp ||= "";

  $linelen -= length($lp);

  # Figure out how to print the first line
  if (!$break || length($fline)<=$indent) {
    $fline=substr("$fline$space", 0, length($space));
  }
  else {
    # length($fline)>$indent
    $fline="$fline\n$space";
  }

  # Now go through the list, appending until we fill
  # each line. Lather, rinse, repeat.
  my $str="";
  my $line="";
  foreach (@list) {
    $line.=$separator if $line;
    if ($linelen && length($line)+length($_)+length($space)>=$linelen) {
      $line=~s/\s*$//;
      $str.="$space$line\n";
      $line="";
    }
    $line.="$_";
  }

  # Finishing touches - insert first line and line prefixes, if any.
  $str.="$space$line";
  $fline = GREEN . $fline . RESET;
  $str=~s/^$space/$fline/;
  $str=~s/^/$lp/mg if $lp;
  return $str;
}

# Gets a string, and returns it nicely formatted and word-wrapped. It
# uses _sprintlist as a backend. Its syntax is the same as
# _sprintlist, except that is gets a string instead of a list ref, and
# that $separator is not used because we automatically break on white
# space.
# Syntax: _sprintstr($string[, $firstline[, $indent[, $break[, $linelen
#		[, $lineprefix]]]]]);
# See _sprintlist for the meaning of each parameter.
sub _sprintstr {
  my ($str, $fl, $ind, $br, $len, $lp)=@_;
  # Split string into \n-separated parts, preserving all empty fields.
  my @strs = split(/\n/, $str, -1);
  # Now process each line separately, to preserve EOLs that were
  # originally present in the string.
  my $s;
  my $result;
  while (defined($s=shift @strs)) {
    # Split in words.
    my @words=(split(/\s+/, $s));
    $result.=_sprintlist(\@words,$fl," ",$ind,$br,$len, $lp);
    # Add EOL if needed (if there are still more lines to process)
    $result.="\n" if scalar(@strs);
    # The $firstline is only needed at the beginning of the first string.
    $fl=undef;
  }
  return $result;
}

sub print_help {
  # This code is destructive on @options_desc - it's OK because the
  # program always exits after printing help.
  while (my ($cmd, $spec) = (shift @options_desc, shift @options_desc)) {
    last unless defined($cmd);
    if ($cmd =~ /^---/) {
      print _sprintstr($spec, "", 0)."\n";
    }
    else {
      my ($desc, $argname)=split(/\|/, $spec);
      my $arg = $argname ? " $argname" : "";
      my $negatable = ($cmd =~ /!/) ? "[no-]" : "";
      $cmd =~ s/[:=](.).*$//;
      my @variations = map { length($_)>2 ? "--$negatable$_" : "-$_" } split(/[|!]/, $cmd);
      my $maincmd = shift @variations;
      my $cmdstr = "$maincmd$arg" . (@variations ? " (".join(" ", @variations).")" : "");
      print _sprintstr($desc, $cmdstr, 30, 1)."\n";
    }
  }
}
