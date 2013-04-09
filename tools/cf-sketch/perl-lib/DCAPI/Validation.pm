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
        if ($dk eq 'derived')
        {
            if (ref $dv ne 'ARRAY')
            {
                return $result->add_error("syntax",
                                          "Validation definition $name is derived from an invalid thingie");
            }

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

    my $choice = Util::hashref_search($d, qw/choice/);
    if (defined $choice)
    {
        if (ref $choice ne 'ARRAY')
        {
            return $result->add_error([qw/choice validation/],
                                      "The choice was not an array ref");
        }

        $self->api()->log4("Validating %s: checking choice %s",
                           $self->name,
                           $choice);
        return $result->add_error([qw/choice validation/],
                                  "The value '$data' was not in [@$choice]")
         unless grep { $_ eq $data } @$choice;
    }

    my $minimum_value = Util::hashref_search($d, qw/minimum_value/);
    if (defined $minimum_value)
    {
        $self->api()->log4("Validating %s: checking minimum value %s",
                           $self->name,
                           $minimum_value);
        return $result->add_error([qw/minimum_value validation/],
                                  "The value '$data' was above $minimum_value")
         if $data < $minimum_value;
    }

    my $maximum_value = Util::hashref_search($d, qw/maximum_value/);
    if (defined $maximum_value)
    {
        $self->api()->log4("Validating %s: checking maximum value %s",
                           $self->name,
                           $maximum_value);
        return $result->add_error([qw/maximum_value validation/],
                                  "The value '$data' was above $maximum_value")
         if $data > $maximum_value;
    }

    my $invalid_regex = Util::hashref_search($d, qw/invalid_regex/);
    if (defined $invalid_regex)
    {
        $self->api()->log4("Validating %s: checking invalid_regex %s",
                           $self->name,
                           $invalid_regex);
        return $result->add_error([qw/invalid_regex validation/],
                                  "The value '$data' matched forbidden '$invalid_regex'")
         if $data =~ m/$invalid_regex/;
    }

    my $valid_regex = Util::hashref_search($d, qw/valid_regex/);
    if (defined $valid_regex)
    {
        $self->api()->log4("Validating %s: checking valid_regex %s",
                           $self->name,
                           $valid_regex);
        return $result->add_error([qw/valid_regex validation/],
                                  "The value '$data' did not match '$valid_regex'")
         if $data !~ m/$valid_regex/;
    }

    my $invalid_ipv4 = Util::hashref_search($d, qw/invalid_ipv4/);
    if (defined $invalid_ipv4)
    {
        $self->api()->log4("Validating %s: checking invalid_ipv4 %s",
                           $self->name,
                           $invalid_ipv4);
        return $result->add_error([qw/invalid_ipv4 validation/],
                                  "The IPv4 '$data' matched forbidden '$invalid_ipv4'")
         if $self->ipmatch($data, $invalid_ipv4);
    }

    my $valid_ipv4 = Util::hashref_search($d, qw/valid_ipv4/);
    if (defined $valid_ipv4)
    {
        $self->api()->log4("Validating %s: checking valid_ipv4 %s",
                           $self->name,
                           $valid_ipv4);
        return $result->add_error([qw/valid_ipv4 validation/],
                                  "The IPv4 '$data' did not match '$valid_ipv4'")
         unless $self->ipmatch($data, $valid_ipv4);
    }

    return $result;
}

sub ipmatch
{
    my $self = shift @_;
    $self->api()->log4("TODO: implement ipmatch()");
    return 0;
}

1;
