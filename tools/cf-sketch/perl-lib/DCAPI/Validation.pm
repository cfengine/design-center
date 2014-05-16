package DCAPI::Validation;

use strict;
use warnings;

use Mo qw/default build builder is required option/;

use DCAPI::Result;

has api => ( is => 'ro', required => 1 );

has name => ( is => 'ro' );
has definition => ( is => 'ro' );

sub data_dump
{
    my $self = shift;
    return
    {
     name => $self->name(),
     definition => $self->definition(),
    };
}

sub make_validation
{
    my $api = shift;
    my $name = shift;
    my $definition = shift;
    my $result = DCAPI::Result->new(api => $api,
                                    status => 1,
                                    success => 1,
                                    data => { });

    if (ref $definition ne 'HASH')
    {
        return $result->add_error("syntax",
                                  "Validation definition $name must be a key-value array reference");
    }

    foreach my $dk (keys %$definition)
    {
        my $dv = $definition->{$dk};

        if (ref $dv ne 'ARRAY' &&
            grep { $_ eq $dk } qw/derived list sequence array_v array_k/)
        {
            return $result->add_error("syntax",
                                      "Validation definition $name has an invalid type: " . ref $dv);
        }

        if ($dk eq 'derived')
        {
            foreach my $parent (@$dv)
            {
                next if exists $api->validations()->{$parent};
                return $result->add_error("syntax",
                                          "Validation definition $name is derived from an unknown parent $parent");
            }
        }
    }

    return DCAPI::Validation->new(api => $api, name => $name, definition => $definition);
}

sub validate
{
    my $self = shift @_;
    my $data = shift @_;

    my $data_type = (ref $data)|| 'scalar_value';

    $self->api()->log4("Validating %s against data '%s'", $self->name(), $data);
    my $result = DCAPI::Result->new(api => $self->api(),
                                    status => 1,
                                    success => 1,
                                    data => { });

    my $d = $self->definition();

    foreach my $derived (@{Util::hashref_search($d, qw/derived/) || []})
    {
        my $check = $self->api()->validate({ validation => $derived,
                                             data => $data});
        $self->api()->log4("Validating %s: checking parent data type %s",
                           $self->name,
                           $derived);
        next if $check->success();
        return $check->add_error([qw/derived validation/],
                                 "Could not validate parent type $derived");
    }

    my @or = @{Util::hashref_search($d, qw/or/) || []};
    foreach my $or (@or)
    {
        my $check = $self->api()->validate({ validation => $or,
                                             data => $data});
        $self->api()->log4("Validating %s: checking parent data type %s",
                           $self->name,
                           $or);
        return $check if $check->success();
    }

    return $result->add_error([qw/or validation/],
                              "Could not validate any of the 'or' types @or")
     if scalar @or;

    my $choice = Util::hashref_search($d, qw/choice/);
    if (defined $choice)
    {
        return $result->add_error([qw/choice validation/],
                                  "The choice validation can't take a $data_type")
         if ref $data ne '';

        if (ref $choice ne 'ARRAY')
        {
            my $file = (ref $choice eq 'HASH') && Util::hashref_search($choice, qw/file/);
            if ($file && -r $file)
            {
                open my $fp, '<', $file
                 or return $result->add_error([qw/choice validation/],
                                              "The choice's file: pointer pointed to an unreadable file '$file': $!");
                my @choices;
                while (<$fp>)
                {
                    chomp;
                    push @choices, $_;
                }
                $choice = \@choices;
            }
            else
            {
                return $result->add_error([qw/choice validation/],
                                          "The choice is not an array ref or a valid file: pointer");
            }
        }

        if (!isscalarref($data))
        {
            $self->api()->log4("Validating %s: checking choice %s",
                               $self->name,
                               $choice);
            return $result->add_error([qw/choice validation/],
                                      "The value '$data' is not in [@$choice]")
             unless grep { $_ eq $data } @$choice;
        }
        else
        {
            $self->api()->log5("Validating %s: scalar ref allowed 'choice'",
                               $self->name);
        }
    }

    my $minimum_value = Util::hashref_search($d, qw/minimum_value/);
    if (defined $minimum_value)
    {
        return $result->add_error([qw/minimum_value validation/],
                                  "The minimum_value validation can't take a $data_type")
         if ref $data ne '';

        if (!isscalarref($data))
        {
            return $result->add_error([qw/minimum_value validation/],
                                      "The minimum_value validation can't take a non-numeric value")
             if $data !~ m/^-?\d+$/;

            $self->api()->log4("Validating %s: checking minimum value %s",
                               $self->name,
                               $minimum_value);
            return $result->add_error([qw/minimum_value validation/],
                                      "The value '$data' is below $minimum_value")
             if $data < $minimum_value;
        }
        else
        {
            $self->api()->log5("Validating %s: scalar ref allowed 'minimum'",
                               $self->name);
        }
    }

    my $maximum_value = Util::hashref_search($d, qw/maximum_value/);
    if (defined $maximum_value)
    {
        return $result->add_error([qw/maximum_value validation/],
                                  "The maximum_value validation can't take a $data_type")
         if ref $data ne '';

        if (!isscalarref($data))
        {
            return $result->add_error([qw/maximum_value validation/],
                                      "The maximum_value validation can't take a non-numeric value")
             if $data !~ m/^-?\d+$/;

            $self->api()->log4("Validating %s: checking maximum value %s",
                               $self->name,
                               $maximum_value);
            return $result->add_error([qw/maximum_value validation/],
                                      "The value '$data' is above $maximum_value")
             if $data > $maximum_value;
        }
        else
        {
            $self->api()->log5("Validating %s: scalar ref allowed 'maximum'",
                               $self->name);
        }
    }

    my $invalid_regex = Util::hashref_search($d, qw/invalid_regex/);
    if (defined $invalid_regex)
    {
        return $result->add_error([qw/invalid_regex validation/],
                                  "The invalid_regex validation can't take a $data_type")
         if ref $data ne '';

        if (!isscalarref($data))
        {
            $self->api()->log4("Validating %s: checking invalid_regex %s",
                               $self->name,
                               $invalid_regex);
            return $result->add_error([qw/invalid_regex validation/],
                                      "The value '$data' matches forbidden pattern '$invalid_regex'")
             if $data =~ m/$invalid_regex/;
        }
        else
        {
            $self->api()->log5("Validating %s: scalar ref passes 'regex'",
                               $self->name);
        }
    }

    my $valid_regex = Util::hashref_search($d, qw/valid_regex/);
    if (defined $valid_regex)
    {
        return $result->add_error([qw/valid_regex validation/],
                                  "The valid_regex validation can't take a $data_type")
         if ref $data ne '';

        if (!isscalarref($data))
        {
            $self->api()->log4("Validating %s: checking valid_regex %s",
                               $self->name,
                               $valid_regex);
            return $result->add_error([qw/valid_regex validation/],
                                      "The value '$data' does not match '$valid_regex'")
             if $data !~ m/$valid_regex/;
        }
        else
        {
            $self->api()->log5("Validating %s: scalar ref passes 'regex'",
                               $self->name);
        }
    }

    my $invalid_ipv4 = Util::hashref_search($d, qw/invalid_ipv4/);
    if (defined $invalid_ipv4)
    {
        return $result->add_error([qw/invalid_ipv4 validation/],
                                  "The invalid_ipv4 validation can't take a $data_type")
         if ref $data ne '';

        if (!isscalarref($data))
        {
            $self->api()->log4("Validating %s: checking invalid_ipv4 %s",
                               $self->name,
                               $invalid_ipv4);
            return $result->add_error([qw/invalid_ipv4 validation/],
                                      "The IPv4 '$data' matches the forbidden pattern '$invalid_ipv4'")
             if $self->ipmatch($data, $invalid_ipv4);
        }
        else
        {
            $self->api()->log5("Validating %s: scalar ref passes 'ipv4'",
                               $self->name);
        }
    }

    my $valid_ipv4 = Util::hashref_search($d, qw/valid_ipv4/);
    if (defined $valid_ipv4)
    {
        return $result->add_error([qw/valid_ipv4 validation/],
                                  "The valid_ipv4 validation can't take a $data_type")
         if ref $data ne '';

        if (!isscalarref($data))
        {
            $self->api()->log4("Validating %s: checking valid_ipv4 %s",
                               $self->name,
                               $valid_ipv4);
            return $result->add_error([qw/valid_ipv4 validation/],
                                      "The IPv4 '$data' does not match '$valid_ipv4'")
             unless $self->ipmatch($data, $valid_ipv4);
        }
        else
        {
            $self->api()->log5("Validating %s: scalar ref passes 'ipv4'",
                               $self->name);
        }
    }

    my $list = Util::hashref_search($d, qw/list/);

    if (defined $list)
    {
        return $result->add_error([qw/list validation/],
                                  "The 'list' validation can't take a $data_type")
         if ref $data ne 'ARRAY';

        $self->api()->log4("Validating %s: checking 'list' is %s",
                           $self->name,
                           $list);

        if (scalar @$data)
        {
            my $ok = 0;
            foreach my $list_type (@$list)
            {
                next if $ok;

                my $each_ok = 1;
                foreach my $element (@$data)
                {
                    my $check = $self->api()->validate({ validation => $list_type,
                                                         data => $element});
                    $each_ok &&= $check->success();
                }
                $ok ||= $each_ok;
            }

            unless ($ok)
            {
                return $result->add_error([qw/list validation/],
                                          "Could not validate any of the allowed list types [@$list]");
            }
        }
    }

    my $sequence = Util::hashref_search($d, qw/sequence/);

    if (defined $sequence)
    {
        return $result->add_error([qw/sequence validation/],
                                  "The 'sequence' validation can't take a $data_type")
         if ref $data ne 'ARRAY';

        $self->api()->log4("Validating %s: checking 'sequence' is %s",
                           $self->name,
                           $sequence);

        if (scalar @$data ne scalar @$sequence)
        {
            return $result->add_error([qw/length_mismatch sequence validation/],
                                      "The 'sequence' validation and the data have different lengths")
        }

        my @data = @$data;
        foreach my $seq_type (@$sequence)
        {
            my $element = shift @data;

            my $check = $self->api()->validate({ validation => $seq_type,
                                                 data => $element});
            return $result->add_error([qw/element sequence validation/],
                                      "Sequence element $seq_type does not validate against the given data")
             unless $check->success();
        }
    }

    foreach my $atype (qw/array_k array_v/)
    {
        my $k = Util::hashref_search($d, $atype);
        my $strictMatch = Util::hashref_search($d, 'array_map_strict');
        my $permissiveMatch = Util::hashref_search($d, 'array_map_permissive');


        if (defined $k)
        {
            return $result->add_error([$atype, qw/validation/],
                                      "The '$atype' validation can't take a $data_type")
            if ref $data ne 'HASH';

            $self->api()->log4("Validating %s: checking '$atype' is %s",
                               $self->name,
                               $k);

            my @data = $atype eq 'array_k' ? keys %$data : values %$data;
            if (scalar @data)
            {
                my $ok = 0;
                foreach my $k_type (@$k)
                {
                    next if $ok;

                    my $each_ok = 1;
                    my $dataIndex = 0;
                    my $check;

                    foreach my $element (@data)
                    {
                        if (defined $strictMatch)
                        {
                            return $result->add_error([$atype, qw/validation/],
                                                   "Invalid array_map_strict data: '$strictMatch'")
                                unless ref $strictMatch eq 'HASH';

                            $self->api()->log4("Validating array strict with name %s: checking '$atype' is %s with array strict %s",
                               $self->name,
                               $k,
                               $strictMatch);

                            my @requiredKeys = keys %$strictMatch;
                            my @dataKeys =  keys %$data;


                            if ($atype eq 'array_k')
                            {
                                $self->api()->log4("Validating array strict with name %s: checking [@requiredKeys] contains %s",
                                                   $self->name
                                                   ,$element);
                                # check if we have keys in the specified required array
                                return $result->add_error([qw/key validation/],
                                  "The key '$element' is not valid.")
                                  unless grep { $_ eq $element } @requiredKeys;

                                  next;

                            }

                            if ($atype eq 'array_v')
                             {
                                # validate the data with they key
                                my $keyIndex = $dataKeys[$dataIndex];
                                my $validationType = $strictMatch->{$keyIndex};
                                $self->api()->log4("Validating array strict with value %s with validation type %s",$element,$validationType);
                                $check = $self->api()->validate({ validation => $validationType,
                                                                  data => $element});
                             }
                        }
                        elsif(defined $permissiveMatch)
                        {
                            return $result->add_error([$atype, qw/validation/],
                                                   "Invalid array_map_permissive data: '$permissiveMatch'")
                                unless ref $permissiveMatch eq 'HASH';

                          $self->api()->log4("Validating array permissive with name %s: checking '$atype' is %s with array permissive %s",
                                             $self->name,
                                             $k,
                                             $permissiveMatch);

                              my @dataKeys = keys %$data ;

                              if ($atype eq 'array_v')
                              {
                                my $keyIndex = $dataKeys[$dataIndex];

                                if (defined $keyIndex)
                                {
                                  my $validationType = $permissiveMatch->{$keyIndex};
                                  if (defined $validationType)
                                  {
                                    $self->api()->log4("Validating array permissive with value %s with validation type %s",$element,$validationType);
                                    $check = $self->api()->validate({ validation => $validationType,
                                                                      data => $element});
                                  }
                                  else
                                  {
                                   # Do generic check for array value
                                   $check = $self->api()->validate({ validation => $k_type,
                                                                     data => $element});
                                  }
                               }
                             }
                             if ($atype eq 'array_k')
                             {
                               # for keys just do a generic check
                               $check = $self->api()->validate({ validation => $k_type,
                                                                 data => $element});
                             }
                        }
                        else
                        {
                            # If no array permissive or strict is defined
                            $self->api()->log4("generic array validation with type  %s and value %s",$element,$k_type);
                            $check = $self->api()->validate({ validation => $k_type,
                                                              data => $element});
                        }

                        $each_ok &&= $check->success();
                        $dataIndex++;
                    }

                    $ok ||= $each_ok;
                }

                unless ($ok)
                {
                    return $result->add_error([$atype, qw/validation/],
                                              "Could not validate any of the allowed $atype types [@$k]");
                }
            }
        }
    }

    return $result;
}

sub ipmatch
{
    my $self = shift @_;
    $self->api()->log4("TODO: implement ipmatch()");
    return 0;
}

# this checks the form $(...) (inside you can have "namespace:bundle.varname")
sub isscalarref
{
    my $string = shift @_;
    return $string =~ m/^\$\([\w:.]+\)$/;
}

1;
