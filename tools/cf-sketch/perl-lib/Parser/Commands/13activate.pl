#
# configure/activate command
#
# CFEngine AS, October 2012
#
# Time-stamp: <2013-04-10 02:29:01 a10022>

use Term::ANSIColor qw(:constants);

use Util;

######################################################################

%COMMANDS =
  (
   'activate' =>
   [
    [
     'activate SKETCH PARAMSETNAME|FILE[,...] [ENVIRONMENT|CLASSEXP]',
     'Activate the given sketch using the named parameter sets and environment. If a FILE path is provided, it is read to create a new parameter set named after its path. If a existing named ENVIRONMENT is given, it is used to activate the sketch. If the ENVIRONMENT does not exist, it is considered to be a class expression and a new environment is created on the fly.',
     '(\S+)\s+(\S+)(?:\s+(\S+))?',
     'activate'
    ],
    # [
    #  '-configure SKETCH[#n]',
    #  'Configure the given sketch interactively. If #n is specified, the indicated instance is edited instead of creating a new one.',
    #  '(\S+)',
    #  'configure_interactive'
    # ],
   ]
  );

######################################################################

sub is_sketch_installed
{
  my $sketch = shift;
  # Read installed sketches
  my ($success, $result) = main::api_interaction({ list => "." });
  my $list = Util::hashref_search($result, 'data', 'list');
  unless (ref $list eq 'HASH')
  {
      Util::error("Error: invalid data returned in list of installed sketches: $list.\n");
      return undef;
  }
  foreach my $r (keys %$list)
  {
      return 1 if (grep { $sketch eq $_ } keys %{$list->{$r}});
  }
  return undef;
}

sub command_activate {
  my $sketch = shift;
  my $params = shift;
  my $env    = shift;
  my @params = split(/,/, $params);
  my ($success, $result);

  # Read existing definitions
  ($success, $result) = main::api_interaction({ definitions => 1 });
  return unless $success;
  my $defs = Util::hashref_search($result, 'data', 'definitions');
  $defs = {} unless (ref $defs eq 'HASH');
  # Read existing environments
  ($success, $result) = main::api_interaction({ environments => 1 });
  return unless $success;
  my $envs = Util::hashref_search($result, 'data', 'environments');
  $envs = {} unless (ref $envs eq 'HASH');

  my %todefine=();
  my %todo=();

  unless (is_sketch_installed($sketch))
  {
      Util::error("Sketch $sketch is not installed - please install it before configuring it.\n");
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
      }
      elsif (-f $p)
      {
          # If it's an existing file, load and define it
          my $load = $Config{dcapi}->load($p);
          die "Could not load $p: $!" unless defined $load;

          if (ref $load eq 'ARRAY')
          {
              my $i = 1;
              foreach (@$load)
              {
                  my $k = "$p $i";
                  $todefine{$k} = $_;
                  $i++;
                  push @todoparams, $k;
              }
          }
          else
          {
              $todefine{$p} = $load;
              push @todoparams, $p;
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
  }
  elsif (exists($envs->{$env})) {
    # Use the named one if it already exists
    $envname = $env;
  }
  else {
    # Define new environment, named after the given class expression
    my $classexp = $env;
    # Sanitize environment name so it's a valid bundle name
    $env =~ s/\W+/_/g;
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

1;
