#
# configure/activate command
#
# CFEngine AS, October 2012
#
# Time-stamp: <2012-10-09 14:38:10 a10022>

use Term::ANSIColor qw(:constants);

use Util;
use Term::ReadLine;
use DesignCenter::Config;
use DesignCenter::JSON;

######################################################################

%COMMANDS =
  (
   'configure' =>
   [
    [
     'configure SKETCH [FILE.json]',
     'Configure the given sketch using the parameters from FILE.json or interactively if the file is ommitted.',
     '(\S+)\s+(\S+)',
     'configure_file'
    ],
    [
     '-configure SKETCH',
     'Configure the given sketch interactively.',
     '(\S+)',
     'configure_interactive'
    ],
   ]
  );

######################################################################

sub find_sketch {
  my $sketch = shift;
  my $res=DesignCenter::Config->_system->list(["."]);
  unless (exists($res->{$sketch})) {
    Util::error "Sketch $sketch is not installed, please use the 'install' command first.\n";
    return undef;
  }
  return $res->{$sketch}
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
  my $name = $var->{name};
  my $type = $var->{type};
  my $def  = (DesignCenter::JSON::recurse_print($var->{default}, undef, 1))[0]->{value};
  my $value;
  my $valid;

  # List values
  if ($type =~ m/^LIST\((.+)\)$/) {
    my $subtype = $1;
    Util::output(GREEN."\nParameter $name must be a list of $subtype.\n".RESET);
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
    Util::output(GREEN."\nParameter $name must be an array.\n".RESET);
    Util::output("Please enter each key and value in turn, empty key to finish.\n");
    my $val = {};
    while (1) {
      do {
        $valid = 0;
        my $k = $input->readline("Please enter next key: ");
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
          my $v = $input->readline("Please enter value for $name\[$k\]: ");
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
    Util::output(GREEN."\nParameter $name must be a $type.\n".RESET);
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
  my $sketch = shift;

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
        Parser::_message("Entering interactive configuration for sketch $sketch.\nPlease enter the requested parameters (enter STOP to abort):\n");
        my $input = Term::ReadLine->new("cf-sketch-interactive");
        foreach my $var (@$varlist) {
          my ($value, $stop) = query_and_validate($var, $input);
          if ($stop) {
            Util::warning "Interrupting sketch configuration.\n";
            return;
          }
          $params->{$var->{name}} = $value;
        }
        # Parameter input complete, let's activate it
        unless (DesignCenter::Sketch::install_config($sketch, $params)) {
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
