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

    my $result = DCAPI::Result->new(api => $self->api(),
                                    status => 1,
                                    success => 1,
                                    data => { });

    return $result->add_error("validation", "TODO: not implemented");
}

1;
