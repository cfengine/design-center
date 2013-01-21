#
# DesignCenter::System
#
# Local system, including its installed sketches
#
# CFEngine AS, October 2012

package DesignCenter::System;

use Carp;
use Term::ANSIColor qw(:constants);
use File::Basename;
use File::Spec;

use DesignCenter::Config;
use DesignCenter::Repository;
use DesignCenter::Sketch;

our $AUTOLOAD;                  # it's a package global

# Allowed data fields, for setters/getters
our %fields = (
              install_dest => undef,
             );

######################################################################

# Automatically generate setters/getters, i.e. MAGIC
sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;             # strip fully-qualified portion

    unless (exists $self->{_permitted}->{$name} ) {
        croak "Can't access `$name' field in class $type";
    }

    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}

sub new {
    my $class = shift;
    my $installdst = shift;
    # Data initialization
    my $self  = {
        _permitted => \%fields,
        %fields,
    };
    # Get the install destination from the argument if provided (else see default value above)
    $self->{install_dest} = $installdst || DesignCenter::Config->installtarget || $self->{install_dest};
    die "Need the installation target for creation" unless $self->{install_dest};

    # Convert myself into an object
    bless($self, $class);

    return $self;
}

sub list
  {
    my $self = shift;
    my $terms = shift;
    my $noactivations = shift || 0;

    my $res = {};

    foreach my $repo (@{DesignCenter::Config->repolist}) {
      my @sketches = $self->list_internal($repo, $terms);

      my $contents = CFSketch::repo_get_contents($repo);

      if (!scalar @sketches) {
        return $res;
      }
      foreach my $sketch (@sketches) {
        # Create new Sketch object
        $res->{$sketch} = DesignCenter::Sketch->new(name => $sketch, %{$contents->{$sketch}});
        # Set installed to its full install location
        $res->{$sketch}->installed($res->{$sketch}->fulldir);
      }
    }

    # Merge activation info
    unless ($noactivations) {
      my $activations = $self->activations;
      foreach my $sketch (sort keys %$activations) {
        next unless exists($res->{$sketch});
        if ('HASH' eq ref $activations->{$sketch}) {
          Util::color_warn "Skipping unusable activations for sketch $sketch!";
          next;
        }
        $res->{$sketch}->_activations($activations->{$sketch});
        $res->{$sketch}->num_instances(scalar(@{$activations->{$sketch}}));
      }
    }

    return $res;
  }

sub list_internal
  {
    my $self  = shift;
    my $repo  = shift;
    my $terms = shift;

    my @ret;

    print "Looking for terms [@$terms] in cf-sketch repository [$repo]\n"
      if DesignCenter::Config->verbose;

    my $contents = CFSketch::repo_get_contents($repo);
    print "Inspecting repo contents: ", DesignCenter::JSON->coder->encode($contents), "\n"
      if DesignCenter::Config->verbose;

    foreach my $sketch (sort keys %$contents) {
      # TODO: improve this search
      my $as_str = $sketch . ' ' . DesignCenter::JSON->coder->encode($contents->{$sketch});

      foreach my $term (@$terms) {
        next unless $as_str =~ m/$term/i;
        push @ret, $sketch;
        last;
      }
    }

    return @ret;
  }

sub activations {
  my $self=shift;
  my $activations = DesignCenter::JSON::load(DesignCenter::Config->actfile, 1);
  unless (defined $activations && ref $activations eq 'HASH') {
    Util::error "Can't load any activations from ".DesignCenter::Config->actfile."\n"
        if DesignCenter::Config->verbose;
#    Util::error "There are no configured sketches.\n";
    return undef;
  }
  return $activations;
}

# generate the actual cfengine config that will run all the cf-sketch bundles
sub generate_runfile
  {
    my $self=shift;
    my $standalone = shift;
    $standalone = DesignCenter::Config->standalone unless defined($standalone);
    # If a filename is given, use it as is always. If we are using the default,
    # modify it depending on $standalone
    my $run_file = shift;
    unless ($run_file) {
      $run_file = DesignCenter::Config->runfile;
      $run_file = File::Spec->catfile(dirname($run_file), "standalone-".basename($run_file))
        if $standalone;
    }
    # activation successful, now install it
    my $activations = $self->activations;
    return undef unless $activations;

    my $activation_counter = 1;
    my $template_activations = {};

    my @inputs;
    my %dependencies;

  ACTIVATION:
    foreach my $sketch (sort keys %$activations) {
      my $prefix = $sketch;
      $prefix =~ s/::/__/g;

      foreach my $repo (@{DesignCenter::Config->repolist}) {
        my $contents = CFSketch::repo_get_contents($repo);
        if (exists $contents->{$sketch}) {
          if ('HASH' eq ref $activations->{$sketch}) {
            Util::color_warn "Skipping unusable activations for sketch $sketch!\n";
            next;
          }

          my $activation_id = 1;
          foreach my $pdata (@{$activations->{$sketch}}) {
            unless ($pdata->{activated}) {
              print "Skipping configured-but-not-activated activation $activation_id for sketch $sketch\n"
                if DesignCenter::Config->verbose;
              next;
            }
            print "Loading activation $activation_id for sketch $sketch\n"
              if DesignCenter::Config->verbose;
            do { Util::error "Couldn't load activation params for $sketch: $!\n"; next; }
                unless defined $pdata;

            my $data = $contents->{$sketch};

            my %types;
            my %booleans;
            my %vars;

            my $entry_point = DesignCenter::Sketch::verify_entry_point($sketch, $data);

            Util::color_die "Could not load the entry point definition of $sketch"
                unless $entry_point;

            # for null entry_point and interface definitions, don't write
            # anything in the runme template
            unless (exists $entry_point->{bundle_name}) {
              my $input = CFSketch::make_include($data->{fulldir}, dirname($run_file) , @{$data->{interface}});
              push @inputs, $input;
              print "Entry point: added input $input for runfile $run_file\n"
                if DesignCenter::Config->verbose;
              next;
            }

            $dependencies{$_} = 1 foreach CFSketch::collect_dependencies($data->{metadata}->{depends});
            my $activation = {
                              file => File::Spec->catfile($data->{dir}, $data->{entry_point}),
                              dir => $data->{dir},
                              fulldir => $data->{fulldir},
                              entry_bundle => $entry_point->{bundle_name},
                              entry_bundle_namespace => $entry_point->{bundle_namespace},
                              activation_id => $activation_id,
                              dependencies => [ sort keys %dependencies ],
                              pdata  => $pdata,
                              sketch => $sketch,
                              prefix => $prefix,
                             };

            my $varlist = $entry_point->{varlist};

            # provide the metadata that could be useful
            my @files = sort keys %{$data->{manifest}};

            push @$varlist,
              {
               name => 'sketch_depends',
               type => 'slist',
               value => [ sort keys %dependencies ],
              },
                {
                 name => 'sketch_authors',
                 type => 'slist',
                 value => [ sort @{$data->{metadata}->{authors}} ],
                },
                  {
                   name => 'sketch_tags',
                   type => 'slist',
                   value => [ sort @{$data->{metadata}->{tags}} ],
                  },
                    {
                     name => 'sketch_manifest',
                     type => 'slist',
                     value => \@files,
                    };

            my @manifests = (
                             {
                              name => 'sketch_manifest_cf',
                              type => 'slist',
                              value => [ sort grep { $_ =~ m/\.cf$/ } @files ],
                             },
                             {
                              name => 'sketch_manifest_docs',
                              type => 'slist',
                              value => [ sort grep { $data->{manifest}->{$_}->{documentation} } @files ],
                             }
                            );

            push @$varlist, @manifests;

            my %leftovers = map { $_ => 1 } @files;
            foreach my $m (@manifests) {
              foreach (@{$m->{value}}) {
                delete $leftovers{$_};
              }
            }

            if (scalar keys %leftovers) {
              push @$varlist,
                {
                 name => 'sketch_manifest_extra',
                 type => 'slist',
                 value => [ sort keys %leftovers ],
                };
            }

            foreach my $key (qw/version name license/) {
              push @$varlist,
                {
                 name => "sketch_$key",
                 type => 'string',
                 value => '' . $data->{metadata}->{$key},
                };
            }

            $activation->{vars} = $varlist;

            my $ak = sprintf('%03d', $activation_counter++);
            $template_activations->{$ak} = $activation; # the activation counter is 1..N globally!
            $activation_id++;   # the activation ID is 1..N per sketch
          }

          next ACTIVATION;
        }
      }
      do { Util::error "Could not find sketch $sketch in repo list @{DesignCenter::Config->repolist}\n"; return undef; }
    }

    # this removes found keys in %dependencies!
    my @dep_inputs = CFSketch::collect_dependencies_inputs(dirname($run_file), \%dependencies);
    if (DesignCenter::Config->verbose) {
      print "Dependency: added input $_ for runfile $run_file\n"
        foreach @dep_inputs;
    }

    push @inputs, @dep_inputs;

    my @deps = keys %dependencies;
    if (scalar @deps) {
      Util::error "Sorry, can't generate: unsatisfied dependencies [@deps]\n";
      return undef;
    }

    # process input template, substituting variables
    foreach my $a (sort keys %$template_activations) {
      my $act = $template_activations->{$a};
      my $input = CFSketch::make_include($act->{fulldir}, dirname($run_file) , basename($act->{file}));
      push @inputs, $input;
      print "Input template: added input $input for runfile $run_file\n"
        if DesignCenter::Config->verbose;
    }

    my $includes = join ', ', map { my @p = DesignCenter::JSON::recurse_print($_); $p[0]->{value} } Util::uniq(@inputs);

    # maybe make the run template configurable?
    my $output = make_runfile($template_activations, $includes, $standalone, $run_file);

    CFSketch::maybe_write_file($run_file, 'run', $output);
    print GREEN "Generated ".($standalone?"standalone":"non-standalone")." run file $run_file\n"
      unless DesignCenter::Config->quiet;

    # Return generated file path
    return $run_file;
  }

sub make_runfile
  {
    my $activations = shift @_;
    my $inputs      = shift @_;
    my $standalone  = shift @_;
    my $target_file = shift @_;

    my $template = get_run_template();

    my $contexts = '';
    my $vars     = '';
    my $methods  = '';
    my $commoncontrol = '';

    if ($standalone) {
      $commoncontrol=<<'EOHIPPUS';
        body common control
{
    bundlesequence => { "cfsketch_run" };
    inputs => { @(cfsketch_g.inputs) };
}
EOHIPPUS
    }

    foreach my $a (keys %$activations) {
      $contexts .= "       # contexts for activation $a\n";
      $vars .= "       # string and slist variables for activation $a\n";
      my $act = $activations->{$a};
      my @vars = @{$activations->{$a}->{vars}};
      my %params = %{$activations->{$a}->{pdata}};
      my @passed;

      my $rel_path = CFSketch::make_include_path($act->{fulldir}, dirname($target_file));

      my $current_context = '';
      # die Dumper \@vars;
      foreach my $var (@vars) {
        my $name = $var->{name};
        my $value = exists $params{$name} ? $params{$name} :  $var->{value};

        if (ref $value eq 'HASH' &&
            exists $value->{bypass_validation}) {
          $value = $value->{bypass_validation};
          $var->{bypass_validation} = 1;
        }

        if (ref $value eq '') {
          # for when a bundle wants access to scripts or modules
          $value =~ s/__BUNDLE_HOME__/$rel_path/g;
          $value =~ s/__ABS_BUNDLE_HOME__/$act->{fulldir}/g;
          # for when a bundle wants access to the general variables directly
          $value =~ s/__PREFIX__/cfsketch_g._${a}_$act->{prefix}_/g;
          # for when a bundle wants to access its activation's classes
          $value =~ s/__CLASS_PREFIX__/default:_${a}_$act->{prefix}_/g;
          # for when a bundle wants to set unique classes per activation
          $value =~ s/__CANON_PREFIX__/_${a}_$act->{prefix}_/g;
        }

        push @passed, [ $var, $value ]
          if (exists $var->{passed} && $var->{passed});

        my %bycontext;
        if (ref $value eq 'HASH' &&
            exists $value->{bycontext} &&
            ref $value->{bycontext} eq 'HASH') {
          %bycontext = %{$value->{bycontext}};
        } else {
          $bycontext{any} = $value;
        }

        foreach my $context (sort keys %bycontext) {
          if ($var->{type} eq 'CONTEXT') {
            my $as_cfengine_context = $bycontext{$context};
            if (DesignCenter::JSON::is_json_boolean($bycontext{$context})) {
              $as_cfengine_context = $bycontext{$context} ? 'any' : "!any";
            } elsif (ref $as_cfengine_context ne '') {
              Util::error "Unexpected value for CONTEXT $name: " . DesignCenter::JSON->coder->encode($as_cfengine_context)."\n";
              return;
            }

            $contexts .= "     ${context}::\n" if $current_context ne $context;
            $current_context = $context;
            $contexts .= sprintf('      "_%s_%s_%s" expression => "%s";' . "\n",
                                 $a,
                                 $act->{prefix},
                                 $name,
                                 $as_cfengine_context);

            my $print_context = $as_cfengine_context;
            $vars .= "     ${print_context}:: # setting context for text representations\n" if $current_context ne $print_context;
            $current_context = $print_context;
            $vars .= sprintf('       "_%s_%s_contexts[%s]" string => "%s"; # text representation of the context "%s"' . "\n",
                             $a,
                             $act->{prefix},
                             $name,
                             $bycontext{$context},
                             $name);
            $vars .= "     any:: # go back to global\n";

            if ($name eq 'activated') {
              $methods .= sprintf('    _%s_%s_%s::' . "\n",
                                  $a,
                                  $act->{prefix},
                                  $name);
            }
          } else                # regular, non-CONTEXT variable
            {
              $vars .= "     ${context}::\n" if $current_context ne $context;
              $current_context = $context;

              my @p = DesignCenter::JSON::recurse_print($bycontext{$context},
                                    "_${a}_$act->{prefix}_${name}",
                                    0,
                                    DesignCenter::Config->simplifyarrays );
              $vars .= sprintf('       "%s" %s => %s;' . "\n",
                               $_->{path},
                               $_->{type},
                               $_->{value})
                foreach @p;
            }
        }

        do { Util::error("Sorry, but we have an undefined variable '$name': it has neither a parameter value nor a supplied value\n"); return; }
            unless defined $value;
      }

      print "We will activate bundle $act->{entry_bundle} with passed parameters " . DesignCenter::JSON->coder->encode(\@passed) . "\n"
        if DesignCenter::Config->verbose;

      my @print_passed;
      foreach my $pass (@passed) {
        my $var = $pass->[0];
        if ($var->{type} =~ m/^(KV)?ARRAY\(/) {
          push @print_passed, "\"default:cfsketch_g._${a}_$act->{prefix}_$var->{name}\"";
        } else {
          my $islist = $var->{type} =~ m/^LIST\(/;
          my $sigil = $islist ? '@' : '$';
          # my $maybe_quotes = $islist ? '"' : '';
          my $maybe_quotes = '';
          push @print_passed, "$maybe_quotes$sigil(cfsketch_g._${a}_$act->{prefix}_$var->{name})$maybe_quotes";
        }
      }

      my $args = join(", ", @print_passed);

      $methods .= sprintf('      "%s %s %s" usebundle => %s%s(%s);' . "\n",
                          $a,
                          $act->{sketch},
                          $act->{activation_id},
                          $act->{entry_bundle_namespace} ? "$act->{entry_bundle_namespace}:" : '',
                          $act->{entry_bundle},
                          $args);
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

sub deactivate
  {
    my $self = shift;
    my $nums_or_name = shift @_;

    my $activations = DesignCenter::JSON::load(DesignCenter::Config->actfile, 1);
    my %modified;

    if ('' eq ref $nums_or_name) # a string or regex
      {
        my ($name, $num) = split(/#/, $nums_or_name);
        foreach my $sketch (sort keys %$activations) {
          next unless $sketch =~ m/$name/;
          if ($num) {
            splice(@{$activations->{$sketch}}, $num-1, 1);
            $modified{$sketch}++;
            print GREEN "Deactivated: $sketch activation #$num\n".RESET
              unless DesignCenter::Config->quiet;
          }
          else {
            delete $activations->{$sketch};
            $modified{$sketch}++;
            print GREEN "Deactivated: all $sketch activations\n".RESET
              unless DesignCenter::Config->quiet;
          }
        }
      } elsif ('ARRAY' eq ref $nums_or_name) {
        my @deactivations;

        my $offset = 1;
        foreach my $sketch (sort keys %$activations) {
          if ('HASH' eq ref $activations->{$sketch}) {
            Util::color_warn "Ignoring old-style activations for sketch $sketch!";
            $activations->{$sketch} = [];
            $modified{$sketch}++;
            print GREEN "Deactivated: all $sketch activations\n"
              unless DesignCenter::Config->quiet;
          }

          my @new_activations;

          foreach my $activation (@{$activations->{$sketch}}) {
            if (grep { $_ == $offset } @$nums_or_name) {
              $modified{$sketch}++;
              print GREEN "Deactivated: $sketch activation $offset\n" unless DesignCenter::Config->quiet;
            } else {
              push @new_activations, $activation;
            }
            $offset++;
          }

          if (exists $modified{$sketch}) {
            $activations->{$sketch} = \@new_activations;
          }
        }
      } else {
        Util::error "Sorry, I can't handle parameters " . DesignCenter::JSON->coder->encode($nums_or_name);
        return;
      }

    if (scalar keys %modified) {
      CFSketch::maybe_ensure_dir(dirname(DesignCenter::Config->actfile));
      CFSketch::maybe_write_file(DesignCenter::Config->actfile, 'activation', DesignCenter::JSON->coder->encode($activations));
    }
  }

sub remove
  {
    my $self=shift;
    my $toremove = shift @_;

    foreach my $repo (@{DesignCenter::Config->repolist}) {
      next unless Util::is_resource_local($repo);

      my $contents = CFSketch::repo_get_contents($repo);

      foreach my $sketch (sort @$toremove) {
        my @matches = grep
          {
            # accept sketch name or directory
            ($_ eq $sketch) || ($contents->{$_}->{dir} eq $sketch) || ($contents->{$_}->{fulldir} eq $sketch)
          } keys %$contents;

        unless (scalar @matches) {
          Util::warning "I did not find an installed sketch that matches '$sketch' - not removing it.\n";
          next;
        }
        $sketch = shift @matches;
        my $data = $contents->{$sketch};
        if (CFSketch::maybe_remove_dir($data->{fulldir})) {
          $self->deactivate($sketch); # deactivate all the activations of the sketch
          print GREEN "Successfully removed $sketch from $data->{fulldir}\n".RESET unless DesignCenter::Config->quiet;
          CFSketch::repo_clear_cache($repo);
        } else {
          print RED "Could not remove $sketch from $data->{fulldir}\n".RESET unless DesignCenter::Config->quiet;
          CFSketch::repo_clear_cache($repo);
        }
      }
    }
  }

1;
