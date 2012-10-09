#!/usr/bin/env perl -w

# Configuration class

package DesignCenter::Config;

use FindBin;
use Carp;
use Getopt::Long;
use Util;

# We store config in a class-global variable so that it can be
# used without having to pass a $config object all over the place
our $object = {};

# Allow running init() multiple times without reinitializing things
our $init_ran = undef;

my %options = ();

use vars qw($inputs_root $configdir $color);

BEGIN {
  # Inputs directory depending on root/non-root/policy hub
  $inputs_root = $> != 0 ? glob("~/.cfagent/inputs") : (-e '/var/cfengine/state/am_policy_hub' ? '/var/cfengine/masterfiles' : '/var/cfengine/inputs');
  # Configuration directory depending on root/non-root
  $configdir = $> == 0 ? '/etc/cf-sketch' : glob('~/.cf-sketch');
  # Color enabled by default if STDOUT is connected to a tty (i.e. not redirected or piped somewhere).
  $color = -t STDOUT;
}

# Allowed data fields, with default values
my %fields =
  (
   version => "",
   date => "",
   verbose    => 0,
   veryverbose => 0,
   quiet      => 0,
   help       => 0,
   force      => 0,
   fullpath   => 0,
   dryrun  => 0,
   # switched depending on root or non-root
   actfile   => "$configdir/activations.conf",
   configfile => "$configdir/cf-sketch.conf",
   installtarget => File::Spec->catfile($inputs_root, 'sketches'),
   installsource => Util::local_cfsketches_source(File::Spec->curdir()) || 'https://raw.github.com/zzamboni/design-center/features/ease_of_use/sketches/cfsketches',
   params => {},
   cfpath => join (':', Util::uniq(split(':', $ENV{PATH}||''), '/var/cfengine/bin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin')),
   modulepath => '../../',
   runfile => File::Spec->catfile($inputs_root, 'cf-sketch-runfile.cf'),
   standalone => 1,
   simplifyarrays => 0,
   repolist => [ File::Spec->catfile($inputs_root, 'sketches') ],
   color => $color,
   # Internal fields
   _object => undef,
   _repository => undef,
   _system => undef,
   _hash => undef,
  );

# Determine where to load command modules from
(-d ($fields{cmddir}="$FindBin::Bin/../lib/Parser/Commands")) ||
  (-d ($fields{cmddir}="$FindBin::Bin/perl-lib/Parser/Commands")) ||
  ($fields{cmddir}=undef);

######################################################################
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
   "modulepath|mp=s",           "Path to modules relative to the repository root, normally $fields{modulepath}",
   "save-config|config-save",   "Save configuration parameters so that they are automatically loaded in the future.",
   "metarun=s",                 "Load and execute a metarun file of the form { options => \%options }, which indicates the entire behavior for this run.|file",
   "save-metarun=s",            "Save the parameters and actions of the current execution to the named file, for future use with --metarun.|file",

   "---", "\nOptions:\n",
   "quiet|q",                   "Supress non-essential output.",
   "verbose|v",                 "Produce additional output.",
   "veryverbose|vv",            "Produce too much output.",
   "dryrun|n",                  "Do not do anything, just indicate what would be done.",
   "help",                      "This help message.",
   "color!",                    "Colorize output, enabled by default if running on a terminal.",
   "params|p=s%",               "With --activate, override certain parameter values.|param=value",
   "force|f",                   "Ignore dependency/OS/architecture checks. Use with --install and --activate.",
   "cfpath=s",                  "Where to look for CFEngine binaries. Default: $fields{cfpath}.",
   "configfile|cf=s",           "Configuration file to use. Default: $fields{configfile}.|file",
   "runfile|rf=s",              "Where --generate will store the runfile. Default: $fields{runfile}.|file",
   "actfile|af=s",             "Where the information about activated sketches will be stored. Default: $fields{'actfile'}.|file",
   "installtarget|it=s",       "Where sketches will be installed. Default: $fields{'installtarget'}.|dir",
   "json",                      "With --api, produce output in JSON format instead of human-readable format.",
   "standalone|st!",            "With --generate, produce a standalone file (including body common control). Enabled by default, negate with --no-standalone.",
   "simplifyarrays|sa!",       "With --simplifyarrays, simplify 2D arrays in runfile from x[a][b] to x_a[b].",
   "installsource|is=s",       "Location (file path or URL) of a cfsketches catalog file that contains the list of sketches available for installation. Default: $fields{'installsource'}.|loc",
   "repolist|rl=s@",            "Comma-separated list of local directories to search for installed sketches for activation, deactivation, removal, or runfile generation. Default: ".join(', ', @{$fields{repolist}}).".|dirs",
   # "make-package=s@",
   #  "test|t=s@",
   "---", "\nPlease see https://github.com/cfengine/design-center/wiki for the full cf-sketch documentation.",
  );

######################################################################

# Automatically generate setters/getters, i.e. MAGIC
sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self) || $self;

  # If an object was given, use it, otherwise access the class-global
  # options storage
  my $what = ref($self) ? $self : $object;

  my $name = $AUTOLOAD;
  $name =~ s/.*://;             # strip fully-qualified portion

  unless (exists $what->{_permitted}->{$name} ) {
    croak "Can't access `$name' field in class $type";
  }

  if (@_) {
    return $what->{$name} = shift;
  } else {
    return $what->{$name};
  }
}

sub init {
  my $configfile = shift;
  unless ($init_ran) {
    # Data initialization
    $object  = {
                _permitted => \%fields,
                %fields,
               };
    $object->{configfile} = $configfile if $configfile;
    $object->{_hash} = $object;
    $init_ran = 1;
  }
  return $object;
}

sub new {
  my $class = shift;
  # Store in a class-global object
  $self = init(@_);
  $self->{_object} = $self;

  # Convert myself into an object
  bless($self, $class);

  return $self;
}

sub load {
  my $self=shift;

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
  unless ((exists($cmd_options{color}) && $cmd_options{color}) || (!exists($cmd_options{color}) && $self->color)) {
    $ENV{ANSI_COLORS_DISABLED}=1;
  }

  if ($cmd_options{help}) {
    print_help();
    exit;
  }

  my $metarun = $cmd_options{metarun};

  if ($metarun) {
    if (open(my $mfh, '<', $metarun)) {
      # slurp the entire file
      my $jsontxt = join("", <$mfh>);
      my $meta = $coder->decode($jsontxt);

      Util::color_die "Malformed metarun file: no 'options' key"
          unless exists $meta->{options};

      %options = %{$meta->{options}};
    } else {
      Util::color_die "Could not load metarun file $metarun: $!";
    }
  } else {
    # Options given on the config file
    my %cfgfile_options;
    my $cfgfile = $cmd_options{configfile} || $fields{configfile};
    if (open(my $cfh, '<', $cfgfile)) {
      # slurp the entire file
      my $jsontxt = join("", <$cfh>);
      my $given = $coder->decode($jsontxt);

      foreach (sort keys %$given) {
        print "(read from $cfgfile) $_ = ", $coder->encode($given->{$_}), "\n"
          if $cfgfile_options{verbose};
        $cfgfile_options{$_} = $given->{$_};
      }
    }

    # Now we merge all three sources of options: Default options are
    # overriden by config-file options, which are overriden by
    # command-line options
    # The default options are already there, so we just loop over
    # the other two sources (cfgfile and cmdline)
    foreach my $ptr (\%cfgfile_options, \%cmd_options) {
      foreach my $key (keys %$ptr) {
        $self->$key($ptr->{$key});
      }
    }
  }
}

sub print_help {
  # This code is destructive on @options_desc - it's OK because the
  # program always exits after printing help.
  while (my ($cmd, $spec) = (shift @options_desc, shift @options_desc)) {
    last unless defined($cmd);
    if ($cmd =~ /^---/) {
      print Util::sprintstr($spec, "", 0)."\n";
    } else {
      my ($desc, $argname)=split(/\|/, $spec);
      my $arg = $argname ? " $argname" : "";
      my $negatable = ($cmd =~ /!/) ? "[no-]" : "";
      $cmd =~ s/[:=](.).*$//;
      my @variations = map { length($_)>2 ? "--$negatable$_" : "-$_" } split(/[|!]/, $cmd);
      my $maincmd = shift @variations;
      my $cmdstr = "$maincmd$arg" . (@variations ? " (".join(" ", @variations).")" : "");
      print Util::sprintstr($desc, $cmdstr, 30, 1)."\n";
    }
  }
}
