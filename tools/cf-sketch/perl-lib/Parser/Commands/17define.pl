#
# configure/activate command
#
# CFEngine AS, October 2012

use Term::ANSIColor qw(:constants);

use Util;
use Term::ReadLine;

######################################################################

%COMMANDS =
 (
  'define' =>
  [
   [
    'define paramset SKETCH [ PARAMSET [FILE.json] ]',
    'Create a new parameter set for SKETCH named PARAMSET using the parameters from FILE.json, or interactively if the file is ommitted. If PARAMSET is omitted, a name is automatically generated.',
    'param(?:s|set|eters|eterset)?\s+(\S+)\s*(?:\s+(\S+)(?:\s+(\S+))?)?',
    'define_params'
   ],
   [
    'define environment [-n ENV_NAME ] [ ACTIVATION_CLASSEXP [ TEST_CLASSEXP [ VERBOSE_CLASSEXP ] ] ]',
    'Create a new environment named ENV_NAME, with the given conditions for activation, test mode and verbose mode. If ENV_NAME is omitted, a name is automatically generated. If any of the class expressions is omitted, they are interactively queried.',
    'env\S*(?:\s+-n\s*(\S+))?(?:\s+(\S+)(?:\s+(\S+)(?:\s+(\S+))?)?)?',
    'define_env'
   ],
  ]
 );

######################################################################

sub command_define_params {
    my $sketch = shift;
    my $paramset = shift;
    my $file = shift;

    my $defs = main::get_definitions;
    if ($paramset && exists($defs->{$paramset}))
    {
        Util::error("Error: A parameter set named '$paramset' already exists, please use a different name.\n");
        return;
    }
    my $allsk = main::get_all_sketches;
    unless (exists($allsk->{$sketch}))
    {
        Util::error("Error: Sketch '$sketch' does not exist in any of the repositories I know about.\n");
        return;
    }
    if ($file)
    {
        unless ($paramset)
        {
            Util::error("Error: PARAMSET name not provided, but needed to load parameters from a file.\n");
            return;
        }
        my $load = $Config{dcapi}->load($file);
        unless (defined $load)
        {
            Util::error("Error: Could not load $p: $!");
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
        interactive_config($paramset, $defs, $sketch, $allsk->{$sketch});
    }
}

sub interactive_config {
    my ($paramset, $defs, $sketchname, $sketchjson) = @_;
    my $meta = Util::hashref_search($sketchjson, qw/metadata/);
    my $api = Util::hashref_search($sketchjson, qw/api/);
    my @bundles=sort keys %$api;
    my $numbundles = scalar(@bundles);
    my $bundle = undef;
    if ($numbundles == 0)
    {
        Util::error("Sketch $sketchname does not have any configurable parameters!");
        return;
    }
    if ($numbundles > 1)
    {
        my $choice = query_bundle($api);
        if ($choice < 0)
        {
            Util::message("Cancelling configuration.\n");
            return;
        }
        $bundle = $bundles[$choice];
    }
    else
    {
        $bundle = $bundles[0];
    }
    if (!$paramset)
    {
        # Generate a name for the new paramset
        my $base = "$sketchname-$bundle";
        my $i=0;
        do
        {
            $paramset = sprintf("$base-%03d", $i);
            $i++;
        } while (exists($defs->{$paramset}));
        my $newname = Util::single_prompt("Please enter a name for the new parameter set (default: $paramset): ");
        $paramset = $newname || $paramset;
    }
    Util::message("Querying configuration for parameter set '$paramset' for bundle '$bundle'.\n");
    my $data = query_and_validate($api, $bundle);
    if (!$data)
    {
        Util::message("Cancelling configuration.\n");
        return;
    }
    Util::message("Defining parameter set '$paramset' with the entered data.\n");
    my ($success, $result) = main::api_interaction({define => 
                                                    {
                                                     $paramset => { $sketchname => $data },
                                                    }});
    return unless $success;
    Util::success("Parameter set $paramset successfully defined.\n");
}

sub query_bundle {
    my $api=shift;
    my @bundles=();
    foreach my $bundle (sort keys %$api)
    {
        my $bundlestr = "$bundle(" .
         join(", ",
              map { $_->{name} }
              grep { $_->{type} !~ /^(metadata|environment|bundle_options|return)$/ }
              @{$api->{$bundle} } ) .
               ")";
        push @bundles, $bundlestr;
    }
    return Util::choose_one("This sketch has multiple accessible bundles.",
                            "Which one do you want to configure?",
                            @bundles);
}

sub query_and_validate {
    my $api = shift;
    my $bundle = shift;
    my $data = {};

    unless (exists($api->{$bundle}))
    {
        Util::error("Internal error: cannot find API for bundle '$bundle'.\n");
        return undef;
    }

    # Set up input prompt
    my $input = Term::ReadLine->new('interactive-config');
    my @oldhist = $input->GetHistory() if $input->Features->{getHistory};
    $input->clear_history() if $input->Features->{setHistory};

    my $bapi = $api->{$bundle};
    my $value;
    my $valid;
    foreach my $p (@$bapi)
    {
        next if $p->{type} =~ /^(metadata|environment|bundle_options|return)$/;
        do
        {
            $valid = undef;
            $value = prompt_param($p, $input);
            unless (defined($value)) {
                $input->SetHistory(@oldhist) if $input->Features->{setHistory};
                return undef;
            }
            if (exists($p->{validation}))
            {
                $valid = validate_param($p, $value);
            }
            else
            {
                $valid = 1;
            }
        } while (!$valid);
        $data->{$p->{name}} = $value;
    }
    $input->SetHistory(@oldhist) if $input->Features->{setHistory};
    return $data;
}

sub validate_value {
    my $val = shift;
    my $data = shift;
    my ($success, $result) = main::api_interaction({
                                                    validate =>
                                                    {
                                                     validation => $val,
                                                     data => $data,
                                                    }
                                                   });
    return $success;
}

sub validate_param {
    my $p = shift;
    my $value = shift;

    if ($p->{validation} && $value ne '?')
    {
        return validate_value($p->{validation}, $value);
    }
    else
    {
        # If no validation, always return true
        return 1;
    }
}

sub print_validation_help {
    my $val = shift;
    if (!$val)
    {
        Util::warning("This parameter has no validation specified.\n");
    }
    else
    {
        Parser::command_list_vals('-v', "^$val\$", "This parameter needs to validate as a $val:");
    }
}

sub prompt_param {
    my $p = shift;
    my $input = shift;

    my $type = $p->{type};
    my $name = $p->{name};
    my $desc = $p->{description};
    my $ex   = $p->{example};
    my $val  = $p->{validation};

    my @parenstrs = ();
    push @parenstrs, $desc if $desc;
    push @parenstrs, "for example '$ex'" if $ex;
    my $parenstr = "";
    $parenstr = " (".join(", ", @parenstrs).")" if @parenstrs;

    my $ret = undef;
    Util::message("Please enter parameter $name$parenstr.\n");
    Util::message(validationstr($val)."\n") if $val;
    Util::message("  (enter STOP to cancel)\n");
  PROMPT_PARAM:
    $ret = input_param($p, $input);
    if ($ret && $ret eq '?')
    {
        print_validation_help($val);
        goto PROMPT_PARAM;
    }
    return undef if ($ret eq 'STOP');
    return $ret;
}

sub input_scalar {
    my $input = shift;
    my $prompt = shift || "> ";
    my $def = shift;
    my $val = shift;
    my $valid = undef;
    my $data = undef;
    do
    {
        # Default value is included in the prompt
        $data = $input->readline($prompt.($def? "[$def]" : "").": ", $def);
        return $data unless $data;
        # STOP ends data input
        if ($data eq 'STOP')
        {
            return undef;
        }
        if ($val && $data ne '?')
        {
            $valid = validate_value($val, $data);
        }
        else
        {
            $valid = 1;
        }
    } while (!$valid);

    return $data;
}

sub input_param {
    my $p = shift;
    my $input = shift;
    my $prompt = shift;

    my $type = $p->{type};
    my $name = $p->{name};
    my $desc = $p->{description};
    my $ex   = $p->{example};
    my $val  = $p->{validation};
    my $def  = $p->{default} || "";
    my $vals = main::get_validations;
    my $valstruct = $vals->{$val||""};

    my $valid = undef;
    my $data = undef;
    my $elem = undef;
  VALIDATE_PARAM: do
    {
        if ($type eq 'list')
        {
            my @olddata=();
            @olddata = @$def if $def;
            if ($valstruct && $valstruct->{sequence})
            {
                my @seq_elems = @{$valstruct->{sequence}};
                for my $e (@seq_elems)
                {
                    my $def_next = shift @olddata;
                    my $e_val = { validation => $e };
                  INPUT_SCALAR_IN_SEQUENCE:
                    $elem = input_scalar($input, "Next element in sequence ($e)", $def_next, $e_val);
                    return undef unless defined($elem);
                    if ($elem eq '?')
                    {
                        print_validation_help($val);
                        goto INPUT_SCALAR_IN_SEQUENCE;
                    }
                    push @$data, $elem if $elem;
                }
                if (validate_value($val, $data))
                {
                    $valid = 1;
                }
                else
                {
                    Util::error("Invalid data. Please try again.\n");
                    @olddata = @$data;
                    next VALIDATE_PARAM;
                }
            }
            else
            {
                $elem = undef;
                $data = [];
                $valid = 1; # empty lists are valid
                do
                {
                    my $def_next = shift @olddata;
                  INPUT_SCALAR_IN_LIST:
                    $elem = input_scalar($input, "Next element (Enter to finish)", $def_next, undef);
                    return undef unless defined($elem);
                    if ($elem)
                    {
                        if ($elem eq '?')
                        {
                            print_validation_help($val);
                            goto INPUT_SCALAR_IN_LIST;
                        }
                        else
                        {
                            push @$data, $elem;
                            if ($val && !validate_value($val, $data))
                            {
                                Util::error("Invalid data. Please try again.\n");
                                pop @$data;
                                goto INPUT_SCALAR_IN_LIST;
                            }
                            else
                            {
                                $valid = 1;
                            }
                        }
                    }
                } while ($elem);
            }
        }
        elsif ($type eq 'array')
        {
            my %olddata = ();
            %olddata = %$def if $def;
            my @oldkeys = sort keys %olddata;
            $elem = undef;
            $data = {};
            $valid = 1; # empty arrays are valid
            do
            {
                my $def_next_k = shift @oldkeys;
              INPUT_KEY_IN_ARRAY:
                $elem = input_scalar($input, "Next key (Enter to finish)", $def_next_k, undef);
                return undef unless defined($elem);
                if ($elem)
                {
                    if ($elem eq '?')
                    {
                        print_validation_help($val);
                        goto INPUT_KEY_IN_ARRAY;
                    }
                    else
                    {
                        my $elem_v = input_scalar($input, "$name\[$elem\]", $olddata{$elem}, undef);
                        return undef unless defined($elem_v);
                        if ($elem eq '?')
                        {
                            print_validation_help($val);
                            goto INPUT_KEY_IN_ARRAY;
                        }
                        $data->{$elem} = $elem_v;
                        if ($val && !validate_value($val, $data))
                        {
                            Util::error("Invalid data. Please try again.\n");
                            pop @$data;
                            goto INPUT_KEY_IN_ARRAY;
                        }
                        else
                        {
                            $valid = 1;
                        }
                    }
                }
            } while ($elem);
        }
        elsif ($type eq 'string')
        {
            # Call without validation (last param "undef") because this value
            # gets validates upon return.
            $data = input_scalar($input, ($prompt ? $prompt : "$name "), $def, undef);
            # input_scalar() only returns with valid data or undef for STOP
            $valid = 1;
        }
        elsif ($type eq 'boolean')
        {
            my $str = input_scalar($input, ($prompt ? $prompt : "$name "), $def, undef);
            $data = ($str =~ /^(yes|true|1|on)$/i) ? 1 : undef;
            $valid = $str =~ /^(yes|true|1|on|no|false|0|off)$/i;
        }
    } while (!$valid);
    return $data;
}

sub validation_description {
    my $val = shift;
    if ($val->{description})
    {
        return $val->{description};
    }
    elsif ($val->{derived})
    {
        return validation_description($val->{derived});
    }
    elsif ($val->{list})
    {
        return "list of ".join(" or ", map { validation_description($_) } @{$val->{list}});
    }
    elsif ($val->{array_k})
    {
        return "array of [ " .
         join(" or ", map { validation_description($_) } @{$val->{array_k}}) .
         ", " .
         join(" or ", map { validation_description($_) } @{$val->{array_v}}) .
         " ]";
    }
    elsif ($val->{sequence})
    {
        return "sequence of [ ".
         join(" or ", map { validation_description($_) } @{$val->{sequence}}) .
         " ]";
    }
}

sub validationstr {
    my $valname=shift;

    return "" unless $valname;

    my $vals = main::get_validations;
    my $val = $vals->{$valname};
    if ($val)
    {
        if ($val->{description})
        {
            return "This parameter must validate as a ".$val->{description}." (please enter ? at the prompt to see the full definition of this validation).";
        }
        else
        {
            return "This parameter must be a $valname (please enter ? at the prompt to see the full definition of this validation).";
        }
    }
    else
    {
        if ($valname)
        {
            return "This parameter is defined as a '$valname', but I don't have a validation by that name. I will treat it as a scalar and accept anything you type.";
        }
    }
}

######################################################################

sub check_env_name
{
    my $name = shift;
    my $envs = main::get_environments;
    if (exists($envs->{$name})) {
        Util::error("Environment '$name' already exists. Please specify a different name.\n");
        return undef;
    }
    return 1;
}

sub command_define_env
{
    my ($env_name, $activ_exp, $test_exp, $verbose_exp) = @_;

    # If at least $activ_exp is given, then it's non-interactive mode
    if ($activ_exp)
    {
        # Env name defaults to the canonified version of the activation condition
        $env_name    ||= Util::canonify($activ_exp);
        return unless check_env_name($env_name);
        # Test and Verbose default to never
        $test_exp    ||= "!any";
        $verbose_exp ||= "!any";
    }
    else
    {
        # Enter interactive mode. Ask for missing information
        unless ($env_name)
        {
            $env_name = Util::single_prompt("Please enter a name for the new environment: ");
            unless ($env_name)
            {
                Util::warning("Empty name entered - cancelling.\n");
                return;
            }
        }
        return unless check_env_name($env_name);

        Util::message(Util::sprintstr("I will now prompt you for the conditions for activation, test, and verbose mode that will be associated with environment '$env_name'. Please enter them as CFEngine class expressions.\n", undef, 0, undef, undef, undef, 1));
        $activ_exp = Util::single_prompt("Please enter the activation condition: ");
        unless ($activ_exp)
        {
            Util::warning("Empty activation condition entered - cancelling.\n");
            return;
        }
        $test_exp = Util::single_prompt("Please enter the test condition: ", "!any");
        $test_exp ||= "!any";
        $verbose_exp = Util::single_prompt("Please enter the verbose condition: ", "!any");
        $verbose_exp ||= "!any";
    }
    my ($success, $result) = main::api_interaction({define_environment => 
                                                    {
                                                     $env_name =>
                                                     {
                                                      'activated' => $activ_exp,
                                                      'test' => $test_exp,
                                                      'verbose' => $verbose_exp
                                                     }
                                                    }});
    return unless $success;
    Util::success("Environment '$env_name' successfully defined.\n");
}
