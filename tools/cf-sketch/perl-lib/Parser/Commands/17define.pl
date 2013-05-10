#
# configure/activate command
#
# CFEngine AS, October 2012
#
# Time-stamp: <2013-05-10 01:22:51 a10022>

use Term::ANSIColor qw(:constants);

use Util;
use Term::ReadLine;

######################################################################

%COMMANDS =
  (
   'define' =>
   [
    [
     'define params PARAMSET SKETCH [FILE.json]',
     'Create a new parameter set named PARAMSET for the given SKETCh using the parameters from FILE.json, or interactively if the file is ommitted.',
     'params\s+(\S+)\s+(\S+)(?:\s+(\S+))?',
     'define_params'
    ],
   ]
  );

######################################################################

sub command_define_params {
    my $paramset = shift;
    my $sketch = shift;
    my $file = shift;

    my $defs = main::get_definitions;
    if (exists($defs->{$paramset}))
    {
        Util::error("A parameter set named '$paramset' already exists, please use a different name.\n");
        return;
    }
    my $allsk = main::get_all_sketches;
    unless (exists($allsk->{$sketch}))
    {
        Util::error("Sketch '$sketch' does not exist in any of the repositories I know about.\n");
        return;
    }
    if ($file)
    {
        my $load = $Config{dcapi}->load($file);
        unless (defined $load)
        {
            Util::error("Could not load $p: $!");
            return;
        }
        Util::message("Defining parameter set '$paramset' with data loaded from '$file'.\n");
        my ($success, $result) = main::api_interaction({define => 
                                                        {
                                                         $paramset => $load,
                                                        }});
        return unless $success;
        Util::success("Parameter set $paramset successfully defined.\n");
    }
    else
    {
        Util::error("Interactive configuration mode not implemented yet, sorry.\n");
    }
}

sub command_configure_file {
  my $sketch = shift;
  my $file = shift;

  my $skobj = find_sketch($sketch) || return;
  $skobj->configure_with_file($file);
}

sub query_and_validate {
  my $var = shift;
  my $input = shift;
  my $prev = shift;
  my $name = $var->{name};
  my $type = $var->{type};
  my $def  = $prev || (DesignCenter::JSON::recurse_print($var->{default}, undef, 1))[0]->{value};
  my $value;
  my $valid;

  # List values
  if ($type =~ m/^LIST\((.+)\)$/) {
    my $subtype = $1;
    Util::output(GREEN."\nParameter '$name' must be a list of $subtype.\n".RESET);
    Util::output("Please enter each value in turn, empty to finish.\n");
    my $val = [];
    while (1) {
      do {
        $valid = 0;
        my $elem = $input->readline("Please enter next value: ");
        if ($elem eq 'STOP') {
          return (undef, 1);
        }
        elsif ($elem eq '') {
          # Validate the whole thing
          $valid = DesignCenter::Sketch::validate($val, $type);
          return ($val, 0) if $valid;
          Util::error "List validation failed. Resetting, please reenter all the values.\n";
          $val = [];
        }
        else {
          $valid = DesignCenter::Sketch::validate($elem, $subtype);
          if ($valid) {
            push @$val, $elem;
          } else {
            Util::warning "Invalid value, please reenter it.\n";
          }
        }
      } until ($valid);
    }
  }
  elsif ($type =~ m/^(KV)?ARRAY\(/) {
    Util::output(GREEN."\nParameter '$name' must be an array.\n".RESET);
    Util::output("Please enter each key and value in turn, empty key to finish.\n");
    my $val = {};
    my @keys = ();
    if ($def && ref($def) eq 'HASH') {
      @keys = sort keys %$def;
    }
    while (1) {
      do {
        $valid = 0;
        my $oldkey = shift @keys;
        my $k = $input->readline("Please enter next key".
                                 ($oldkey ? " [$oldkey]: " : ": "), $oldkey);
        if ($k eq 'STOP') {
          return (undef, 1);
        }
        elsif ($k eq '') {
          # Validate the whole thing
          $valid = DesignCenter::Sketch::validate($val, $type);
          return ($val, 0) if $valid;
          Util::error "Array validation failed. Resetting, please reenter all the values.\n";
          $val = {};
        }
        else {
          my $oldval = $def->{$k};
          my $v = $input->readline("Please enter value for $name\[$k\]".
                                  ($oldval ? " [$oldval]: " : ": "), $oldval);
          if ($k eq 'STOP') {
            return (undef, 1);
          }
          else {
            # No validation happens here. Should probably be fixed.
            $val->{$k} = $v;
          }
        }
      } until ($valid);
    }
  }
  else {
    # Scalar values are the easiest
    Util::output(GREEN."\nParameter '$name' must be a $type.\n".RESET);
    do {
      $valid=0;
      my $stop=0;
      $value = $input->readline("Please enter $name".
                                ($def ? " [$def]: ":": "), $def);
      if ($value eq 'STOP') {
        return (undef, 1);
      }
      $valid = DesignCenter::Sketch::validate($value, $type);
      Util::warning "Invalid value, please reenter it.\n" unless $valid;
    } until ($valid);
  }
  return ($value, undef);
}

sub command_configure_interactive {
  my $name = shift;
  my ($sketch, $num) = split(/#/, $name);

  my $skobj = find_sketch($sketch) || return;

  foreach my $repo (@{DesignCenter::Config->repolist}) {
    my $contents = CFSketch::repo_get_contents($repo);
    if (exists $contents->{$sketch}) {
      my $data = $contents->{$sketch};
      my $if = $data->{interface};

      my $entry_point = DesignCenter::Sketch::verify_entry_point($sketch, $data);

      if ($entry_point) {
        my $varlist = $entry_point->{varlist};
        my $params = {};
        if ($num) {
          my @activations = @{$skobj->_activations};
          my $count = $skobj->num_instances;
          if ($num > $count) {
            Util::warning "Configuration instance #$num does not exist.\n";
            return;
          }
          $params = $activations[$num-1];
        }
        Parser::_message("Entering interactive configuration for sketch $sketch.\nPlease enter the requested parameters (enter STOP to abort):\n");
        my $input = Term::ReadLine->new("cf-sketch-interactive");
        foreach my $var (@$varlist) {
          # These are internal parameters, we skip them
          if ($var->{name} =~ /^(prefix|class_prefix|canon_prefix)$/) {
            $params->{$var->{name}} = $params->{$var->{name}} || $var->{default};
            next;
          }
          my ($value, $stop) = query_and_validate($var, $input, $params->{$var->{name}});
          if ($stop) {
            Util::warning "Interrupting sketch configuration.\n";
            return;
          }
          $params->{$var->{name}} = $value;
        }
        # Parameter input complete, let's activate it
        unless (DesignCenter::Sketch::install_config($sketch, $params, $num?($num-1):undef)) {
          Util::error "Error installing the sketch configuration.\n";
          return;
        }
      }
      else {
        Util::error "Can't configure $sketch: missing entry point - it's probably a library-only sketch.";
        return;
      }
    } else {
      Util::error "I could not find sketch $sketch in the repositories. Is the name correct?\n";
      return;
    }
  }

}
