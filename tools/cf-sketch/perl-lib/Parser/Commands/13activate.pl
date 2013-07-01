#
# configure/activate command
#
# CFEngine AS, October 2012

use Term::ANSIColor qw(:constants);

use Util;
use File::Basename;

######################################################################

%COMMANDS =
  (
   'activate' =>
   [
    [
     'activate [-n ACTIVATION_ID] SKETCH PARAMSETNAME|FILE[,...] [ENVIRONMENT|CLASSEXP]',
     'Activate the given sketch using the named parameter sets and environment. If a FILE path is provided, it is read to create a new parameter set named after its path. If a existing named ENVIRONMENT is given, it is used to activate the sketch. If the ENVIRONMENT does not exist, it is considered to be a class expression and a new environment is created on the fly. If -n is specified, the given ACTIVATION_ID is assigned to the new activation, otherwise an activation ID is automatically generated.',
     '(?:-n\s*(\S+)\s+)?(\S+)\s+(\S+)(?:\s+(\S+))?',
     'activate'
    ],
   ]
  );

######################################################################

sub command_activate {
  my $id     = shift;
  my $sketch = shift;
  my $params = shift;
  my $env    = shift;
  my @params = split(/,/, $params);
  my ($success, $result);

  # Read existing definitions
  my $defs = main::get_definitions;
  # Read existing environments
  my $envs = main::get_environments;

  # Check or generate the activation ID
  my $activs = main::get_activations;
  if ($id)
  {
      if (activ_id_exists($activs, $id))
      {
          Util::error("You cannot use activation ID '$id', it already exists.\n");
          return;
      }
      else
      {
          Util::message("Using provided activation ID '$id'.\n");
      }
  }
  else
  {
      my $i=1;
      $i++ while (activ_id_exists($activs, "$sketch-$i"));
      $id="$sketch-$i";
      Util::message("Using generated activation ID '$id'.\n");
  }

  my %todefine=();
  my %todo=();

  unless (main::is_sketch_installed($sketch))
  {
      Util::error("Sketch $sketch is not installed - please install it before activating it.\n");
      return;
  }

  # First check the parameter sets
  my @todoparams=();

  foreach my $p (@params)
  {
      if (exists($defs->{$p}))
      {
          # If it's an existing definition, just use it
          push @todoparams, $p;
          Util::message("Using existing parameter definition '$p'.\n");
      }
      elsif (-f $p)
      {
          # If it's a file, use its basename as the ID for the param definition
          my $p_id = basename($p, '.json');
          # If that ID already exists, use it
          if (exists($defs->{$p_id}))
          {
              push @todoparams, $p_id;
              Util::message("Using existing parameter definition '$p_id'.\n");
          }
          else
          {
              # If it's an existing file, load and define it
              my $load = $Config{dcapi}->load($p);
              die "Could not load $p: $!" unless defined $load;

              if (ref $load eq 'ARRAY')
              {
                  my $i = 1;
                  foreach (@$load)
                  {
                      my $k = "$p_id-$i";
                      $todefine{$k} = $_;
                      $i++;
                      push @todoparams, $k;
                  }
              }
              else
              {
                  $todefine{$p_id} = $load;
                  push @todoparams, $p_id;
              }
          }
      }
      else
      {
          Util::error("I do not know what to do with param set '$p' - it's neither an existing definition nor a file I can load.\n");
          return;
      }
  }

  # Now check the environment/class expression
  my $envname;
  if (!$env) {
    # Use the default if not provided
    $envname = $Config{environment};
    Util::message("Using default environment '$envname'.\n");
  }
  elsif (exists($envs->{$env})) {
    # Use the named one if it already exists
    $envname = $env;
    Util::message("Using existing environment '$envname'.\n");
  }
  else {
    # Define new environment, named after the given class expression
    my $classexp = $env;
    $env = Util::canonify($env);
    Util::message("Defining new environment named '$env' for class expression '$classexp'\n");
    ($success, $result) = main::api_interaction({
                                                 define_environment =>
                                                 {
                                                  "$env" => { activated => $classexp, test => 0, verbose => 0 },
                                                 }
                                                });
    return unless $success;
    $envname = $env;
  }

  push @{$todo{$sketch}},{
                          target => $Config{repolist}->[0],
                          environment => $envname,
                          params => [ @todoparams ],
                          identifier => $id,
                         };
  if (keys %todefine) {
    Util::message("Defining parameter sets: ".join(", ", sort keys %todefine).".\n");
    ($success, $result) = main::api_interaction({define => \%todefine});
    return unless $success;
  }

  foreach my $sketch (keys %todo) {
    foreach my $activation (@{$todo{$sketch}}) {
      Util::message("Activating sketch $sketch with parameters ".join(", ",@{$activation->{params}}).".\n");
      ($success, $result) = main::api_interaction({activate => { $sketch => $activation }});
      return unless $success;
    }
  }
}

sub activ_id_exists {
    my $activs = shift;
    my $id = shift;
    foreach my $sketch (keys %$activs)
    {
        foreach my $act (@{$activs->{$sketch}})
        {
            return 1 if exists($act->{identifier}) && $act->{identifier} eq $id;
        }
    }
    return undef;
}

1;
