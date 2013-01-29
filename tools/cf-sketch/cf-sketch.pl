#!/usr/bin/perl

package CFSketch;

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
use File::Compare;
use File::Copy;
use File::Find;
use File::Spec;
use File::Temp qw/ tempfile tempdir /;
use Cwd;
use File::Path qw(make_path remove_tree);
use File::Basename;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use Parser;
use Util;
use DesignCenter::JSON;
use DesignCenter::API;
use DesignCenter::Config;
use DesignCenter::Repository;
use DesignCenter::System;
use DesignCenter::Sketch;

$Term::ANSIColor::AUTORESET = 1;

my $VERSION="3.4.0b1";
my $DATE="December 2012";


######################################################################
###### Some basic constants and settings.

$CFSketch::SKETCH_DEF_FILE = 'sketch.json';

$| = 1;                         # autoflush

######################################################################

my $config = new DesignCenter::Config;
$config->load;

# Version and date information
$config->version($VERSION);
$config->date($DATE);

# Set up repository
$config->_repository(DesignCenter::Repository->new);
# Local system
$config->_system(DesignCenter::System->new);


######################################################################

my $required_version = '3.4.0';
my $version = cfengine_version();

if (!$config->force && $required_version gt $version) {
    Util::error "I am very sorry, I need CFEngine version $required_version or above to work,\nbut you seem to have version $version installed.\n";
    exit 1;
}

# Allow both comma-separated values and multiple occurrences of --repolist
$config->repolist([ split(/,/, join(',', @{$config->repolist})) ]);

my @list;
foreach my $repo (@{$config->repolist}) {
  if (Util::is_resource_local($repo)) {
    my $abs = File::Spec->rel2abs($repo);
    if ($abs ne $repo) {
      print "Remapped $repo to $abs so it's not relative\n"
        if $config->verbose;
      $repo = $abs;
    }
  } else                        # a remote repository
    {
    }

  push @list, $repo;
}

$config->repolist(\@list);

my $quiet       = $config->quiet;
my $dryrun      = $config->dryrun;
my $veryverbose = $config->veryverbose;
my $verbose     = $config->verbose || $veryverbose;

# Load commands and do other parser initialization
Parser::init('cf-sketch', $config, @ARGV);
Parser::set_welcome_message("[default]\nCFEngine AS, 2012.");

# Make sure at least the stdlib is installed
$config->_repository->install(['CFEngine::stdlib'], 1);

unless ($config->expert || $config->dcapi) {
  # Run the main command loop
  Parser::parse_commands();

  # Finishing code.
  Parser::finish();

  exit(0);
}

#print "Full configuration: ", DesignCenter::JSON->coder->encode(\%options), "\n" if $verbose;

# TODO - fix this
# my $save_metarun = $config->savemetarun;
# if ($save_metarun)
# {
#  maybe_ensure_dir(dirname($save_metarun));
#  maybe_write_file($save_metarun,
#                   'metarun file',
#                   DesignCenter::JSON->coder->pretty(1)->encode({ options => \%options }));
#  print GREEN "Saved metarun file $save_metarun\n";
#  exit;
# }

if ($config->saveconfig) {
  configure_self($config->configfile);
  exit;
}

if ($config->list) {
  # 'all' matches everything
  Parser::command_list(join('|', @{$config->list}));
  exit;
}

if ($config->search) {
  Parser::command_search(join('|', @{$config->search}));
  exit;
}

# if (scalar @{$config->makepackage}) {
#   make_packages($config->makepackage);
#   exit;
# }

if ($config->dcapi)
{
 my $data = DesignCenter::JSON::load(join '', <>);
 my $version = DesignCenter::JSON::hashref_search($data, qw/dc-api-version/);
 my $list = DesignCenter::JSON::hashref_search($data, qw/list/);
 my $search = DesignCenter::JSON::hashref_search($data, qw/search/);
 my $api = DesignCenter::JSON::hashref_search($data, qw/api/);

 if (defined $version && $version eq '0.0.1')
 {
  my $ret = DesignCenter::API::make_ok({log => [],
                                        data => {},
                                        success => 1});

  if (defined $list)
  {
   $ret->{data}->{list} = DesignCenter::Config->_system->list([$list || '.'], 1, 1);
  }
  elsif (defined $search)
  {
   $ret->{data}->{search} = Parser::command_search(($search||'.'), 1);
  }
  else
  {
   $ret = DesignCenter::API::make_ok({log => ["We're OK"], success => 1});
  }

  print DesignCenter::JSON::canonical_coder()->allow_blessed()->encode($ret), "\n";
  exit 0;
 }

 my $ret = DesignCenter::API::make_error(["DC API Version mismatch"]);
 print DesignCenter::JSON::canonical_coder()->allow_blessed()->encode($ret), "\n";
 exit 1;
}

if ($config->listactivations) {
  Parser::command_listactivations();
  exit;
}

if ($config->deactivateall) {
  $config->deactivate('.*');
}

my @nonterminal = qw/deactivate remove install activate generate/;
my @terminal = qw/api search/;
my @callable = (@nonterminal, @terminal);

foreach my $word (@callable) {
  if ($config->$word)
  {
   if ($word eq 'install')
   {
    Parser::command_install(join(' ', @{$config->$word}));
   }
   elsif ($word eq 'remove')
   {
    Parser::command_remove(join(' ', @{$config->$word}));
   }
   elsif ($word eq 'activate')
   {
    activate($config->$word);
   }
   elsif ($word eq 'deactivate')
   {
    DesignCenter::System::deactivate($config->$word);
   }
   elsif ($word eq 'generate')
   {
    Parser::command_generate($config->standalone);
   }
   elsif ($word eq 'search')
   {
    Parser::command_search(join(' ', @{$config->$word}));
   }
   else
   {
    Util::color_die("Internal cf-sketch error: callable $word is not handled");
   }

   # exit unless the command was non-terminal...
   exit unless grep { $_ eq $word } @nonterminal;
  }
}

# now exit if any non-terminal commands were specified
exit if grep { $config->$_ } @nonterminal;

push @callable, 'list', 'save-config';
Util::color_die "Sorry, I don't know what you want to do.  You have to specify a valid verb. Run $0 --help to see the complete list.\n";

sub configure_self
  {
    my $cf    = shift @_;

    my %keys = (
                'repolist' => 1, # array
                'cfpath'   => 0, # string
                installsource => 0,
                installtarget => 0,
                actfile => 0,
                'runfile' => 0,
               );

    print "Saving configuration keys [@{[sort keys %keys]}] to file $cf\n" unless $quiet;

    my %config;

    foreach my $key (sort keys %keys) {
      $config{$key} = $config->$key;
      print "Saving option $key=".tersedump($config{$key})."\n"
        if $verbose;
    }

    maybe_ensure_dir(dirname($cf));
    maybe_write_file($cf, 'configuration input', DesignCenter::JSON->coder->pretty(1)->encode(\%config));
  }

# Produce the appropriate input directory depending on --fullpath
sub inputfile {
  my @paths=@_;
  if ($config->fullpath) {
    return File::Spec->catfile(@paths);
  } else {
    return File::Spec->catfile('sketches', @paths);
  }
}

sub generate {
  DesignCenter::Config->_system->generate_runfile;
}

sub api
  {
    my $sketch = shift @_;

    my $found = 0;
    foreach my $repo (@{$config->repolist}) {
      my $contents = repo_get_contents($repo);
      if (exists $contents->{$sketch}) {
        my $data = $contents->{$sketch};
        my $if = $data->{interface};

        my $entry_point = DesignCenter::Sketch::verify_entry_point($sketch, $data);

        if ($entry_point) {
          $found = 1;

          local $Data::Dumper::Terse = 1;
          local $Data::Dumper::Indent = 0;
          if ($config->json) {
            my %api = (
                       vars => $entry_point->{varlist},
                       returns => $entry_point->{returns},
                      );
            print DesignCenter::JSON->coder->pretty(1)->encode(\%api)."\n";
          } else {
            print GREEN "Sketch $sketch\n";
            if ($data->{entry_point}) {
              print BOLD BLUE."  Entry bundle name:".RESET." $entry_point->{bundle_name}\n";

              foreach my $var (@{$entry_point->{varlist}}) {
                my @p = DesignCenter::JSON::recurse_print($var->{default}) if exists $var->{default};

                my $desc = join ",\t", (
                                        $var->{passed} ? 'passed    ' : 'not passed',
                                        sprintf('%20s', $var->{type}),
                                        exists $var->{default} ? ("optional (default $p[0]->{value})") : "mandatory",
                                       );
                printf("var ".BLUE."%15.15s:".RESET."\t$desc\n",
                       $var->{name});
              }

              foreach my $return (sort keys %{$entry_point->{returns}}) {
                printf("ret ".BLUE."%15.15s:".RESET."\t$entry_point->{returns}->{$return}\n",
                       $return);
              }
            } else {
              print BOLD BLUE "  This is a library sketch - no entry point defined.\n";
            }
          }
        } else {
          Util::color_die "I cannot find API information about $sketch.\n";
        }
      }
    }

    unless ($found)
      {
        Util::color_die "I could not find sketch $sketch. It doesn't seem to be installed.\n";
      }
  }

sub activate {
  my $aspec = shift;
  foreach my $sketch (keys %$aspec) {
    Parser::command_configure_file($sketch, $aspec->{$sketch});
  }
}

# TODO: need functions for: test


sub find_remote_sketches
  {
    my $urls = shift @_;
    my $noparse = shift @_ || 0;
    my %contents;

    foreach my $repo (@$urls) {
      my $sketches_url = "$repo/cfsketches";
      my $sketches = Util::get_remote($sketches_url)
        or Util::color_die "Unable to retrieve $sketches_url : $!\n";

      foreach my $sketch_dir ($sketches =~ /(.+)/mg) {
        my $info = DesignCenter::Sketch->load("$repo/$sketch_dir", undef, $noparse);
        next unless $info;
        $contents{$info->{metadata}->{name}} = $info;
      }
    }

    return \%contents;
  }

sub find_sketches
  {
    my $dirs = shift @_;
    my $noparse = shift @_ || 0;

    my %contents;

    my @dirs = grep { -r $_ && -x $_ } @$dirs;

    if (scalar @dirs) {
      foreach my $topdir (@dirs) {
        find(sub
             {
               my $f = $_;
               if ($f eq $CFSketch::SKETCH_DEF_FILE) {
                 my $info = DesignCenter::Sketch->load($File::Find::dir, $topdir, $noparse);
                 return unless $info;
                 $contents{$info->{metadata}->{name}} = $info;
               }
             }, $topdir);
      }
    }

    return \%contents;
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


sub get_local_repo
  {
    my $repo;
    foreach my $target (@{$config->repolist}) {
      if (Util::is_resource_local($target)) {
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
      my $noparse = shift @_ || 0;

      return $content_cache{$repo,$noparse}
        if exists $content_cache{$repo,$noparse};

      my $contents;
      if (Util::is_resource_local($repo)) {
        $contents = find_sketches([$repo], $noparse);
      } else {
        $contents = find_remote_sketches([$repo], $noparse);
      }

      $content_cache{$repo,$noparse} = $contents;
      return $contents;
    }
  sub repo_clear_cache {
    my $repo = shift;
    delete $content_cache{$repo,0};
    delete $content_cache{$repo,1};
  }
}

# Utility functions follow

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
    if ($dryrun) {
      print YELLOW "DRYRUN: will not ensure/create directory $_[0]\n";
      return 1;
    }

    return ensure_dir($_[0]);
  }

sub maybe_remove_dir
  {
    if ($dryrun) {
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

    if ($dryrun) {
      print YELLOW "DRYRUN: will not write $desc file $file with data\n$data";
    } else {
      open(my $fh, '>', $file)
        or Util::color_die "Could not write $desc file $file: $!";

      print $fh $data;
      close $fh;
    }
  }


{
  my %cf_binaries = ();

  sub cfengine_binary
    {
      my $name = shift || 'cf-promises';

      unless ($cf_binaries{$name})
        {
          foreach my $check_path (split ':', $config->cfpath) {
            my $check = "$check_path/$name";
            $cf_binaries{$name} = $check if -x $check;
            last if $cf_binaries{$name};
          }
        }

      Util::color_die "Sorry, but we couldn't find $name in the search path $config->cfpath.  Please set \$PATH or use the --cfpath parameter!"
          unless $cf_binaries{$name};

      print "Excellent, we found $cf_binaries{$name} to interface with CFEngine\n"
        if $veryverbose;

      return $cf_binaries{$name};
    }

  sub cfengine_version
    {
      my $pb = cfengine_binary('cf-promises');
      my $cfv = `$pb -V`;       # TODO: get this from cfengine?
      if ($cfv =~ m/\s+(\d+\.\d+\.\d+)/) {
        return $1;
      } else {
        print YELLOW "Unsatisfied cfengine dependency: could not get version from [$cfv].\n"
          if $verbose;
        return 0;
      }
    }
}

sub collect_dependencies
  {
    my $deps = shift @_;

    my @collected;

    foreach my $repo (@{$config->repolist}) {
      my $contents = CFSketch::repo_get_contents($repo, 1);
      foreach my $dep (sort keys %$deps) {
        if ($dep eq 'os' || $dep eq 'cfengine') {
        } elsif (exists $contents->{$dep}) {
          my $dd = $contents->{$dep};
          print "Checking dependency match $dep in $repo: " . DesignCenter::JSON->coder->encode($dd) . "\n" if $veryverbose;
          # either the version is not specified or it has to match
          if (!exists $deps->{$dep}->{version} ||
              $dd->{metadata}->{version} >= $deps->{$dep}->{version}) {
            print "Found dependency $dep in $repo\n" if $veryverbose;
            # TODO: test recursive dependencies, right now this will loop
            # TODO: maybe use a CPAN graph module
            push @collected, $dep, collect_dependencies($dd->{metadata}->{depends});
          } else {
            print YELLOW "Found dependency $dep in $repo but the version doesn't match\n"
              if DesignCenter::Config->verbose;
          }
        }
      }
    }

    return @collected;
  }

sub collect_dependencies_inputs
  {
    my $install_dir = shift @_;
    my $dep_map     = shift @_;

    my @inputs;
    foreach my $repo (@{$config->repolist}) {
      my $contents = CFSketch::repo_get_contents($repo, 1);
      foreach my $dep (keys %$dep_map) {
        if (exists $contents->{$dep}) {
          my $input = make_include($contents->{$dep}->{fulldir}, $install_dir , @{$contents->{$dep}->{interface}});
          push @inputs, $input;
          delete $dep_map->{$dep};
        }
      }
    }

    return @inputs;
  }

sub make_include_path
  {
    my $lib_dir = shift @_;
    my $run_dir = shift @_;

    return $config->fullpath ? $lib_dir : File::Spec->abs2rel($lib_dir, $run_dir );
  }

sub make_include
  {
    my $lib_dir = shift @_;
    my $run_dir = shift @_;
    my $file = shift @_;

    my $dir = make_include_path($lib_dir, $run_dir);
    my $input = File::Spec->catfile($dir, $file);
  }

sub tersedump
  {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    return Dumper(shift);
  }


sub search_internal
  {
    my $source = shift @_;
    my $sketches = shift @_;

    my %known;
    my %todo;
    my $local_dir = Util::is_resource_local($source);

    if ($local_dir) {
      Util::color_die "cf-sketch inventory source $source must be a file"
          unless -f $source;

      open(my $invf, '<', $source)
        or Util::color_die "Could not open cf-sketch inventory file $source: $!";

      while (<$invf>) {
        my $line = $_;

        my ($dir, $sketch, $etc) = (split ' ', $line, 3);
        $known{$sketch} = $dir;

        foreach my $s (@$sketches) {
          next unless ($sketch eq $s || $dir eq $s);
          $todo{$sketch} = $dir;
        }
      }
    } else {
      my $invd = Util::get_remote($source)
        or Util::color_die "Unable to retrieve $source : $!\n";

      my @lines = split "\n", $invd;
      foreach my $line (@lines) {
        my ($dir, $sketch, $etc) = (split ' ', $line, 3);
        $known{$sketch} = $dir;

        foreach my $s (@$sketches) {
          next unless ($sketch eq $s || $dir eq $s);
          $todo{$sketch} = $dir;
        }
      }
    }

    return { known => \%known, todo => \%todo };
  }
