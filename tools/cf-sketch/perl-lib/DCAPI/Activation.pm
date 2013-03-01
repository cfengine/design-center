package DCAPI::Activation;

use strict;
use warnings;

use Mo qw/default build builder is required option/;

has api => ( is => 'ro', required => 1 );

has sketch => ( is => 'ro', required => 1 );
has environment => ( is => 'ro', required => 1 );
has bundle => ( is => 'ro', required => 1 );
has params => ( is => 'ro', required => 1 );
has id => ( is => 'ro', required => 1 );

our $activation_position = 1;

sub make_activation
{
    my $api    = shift;
    my $sketch = shift;
    my $spec   = shift;

    if (ref $spec ne 'HASH')
    {
        return (undef, "Invalid activate spec under $sketch");
    }

    my $env = $spec->{environment} || '--environment not given (NULL)--';

    unless (exists $api->environments()->{$env})
    {
        return (undef, "Invalid activation environment '$env'");
    }

    my $found;
    my @repos = grep
    {
        defined $spec->{target} ? $spec->{target} eq $_->location() : 1
    } map { $api->load_repo($_) } @{$api->repos()};

    foreach my $repo (@repos)
    {
        $found = $repo->find_sketch($sketch);
        last if $found;
    }

    return (undef, sprintf("Could not find sketch $sketch in [%s]",
                           join(' ', map { $_->location() } @repos)))
     unless $found;

    my $params = $spec->{params} || "--no valid params array found--";
    if (ref $params ne 'ARRAY')
    {
        return (undef, "Invalid activation params, must be an array");
    }

    unless (scalar @$params)
    {
        return (undef, "Activation params can't be an empty array");
    }

    my %params;
    foreach (@$params)
    {
        return (undef, "The activation params '$_' have not been defined")
         unless exists $api->definitions()->{$_};

        return (undef, "The activation params '$_' do not apply to sketch $sketch")
         unless exists $api->definitions()->{$_}->{$sketch};

        $params{$_} = $api->definitions()->{$_}->{$sketch};
    }

    $api->log3("Verified sketch %s activation: run environment %s and params %s",
               $sketch, $env, $params);

    $api->log4("Checking sketch %s: API %s versus extracted parameters %s",
               $sketch,
               $found->api(),
               \%params);

    my @bundles_to_check = sort keys %{$found->api()};

    # look at the specific bundle if requested
    if (exists $spec->{bundle} &&
        defined $spec->{bundle}) {
        @bundles_to_check = grep { $_ eq $spec->{bundle}} @bundles_to_check;
    }

    my $bundle;
    my @params;
    foreach my $b (@bundles_to_check)
    {
        my $sketch_api = $found->api()->{$b};

        my $params_ok = 1;
        foreach my $p (@$sketch_api)
        {
            $api->log5("Checking the API of sketch %s: parameter %s", $sketch, $p);
            my $filled = fill_param($api,
                                    $p->{name}, $p->{type}, \%params,
                                    {
                                     environment => $env,
                                     # insert a 'default' key only if it exists
                                     (exists $p->{default} ? (default => $p->{default}) : ()),
                                    });
            unless ($filled)
            {
                $api->log4("The API of sketch %s did not match parameter %s", $sketch, $p);
                $params_ok = 0;
                last;
            }

            $api->log5("The API of sketch %s matched parameter %s", $sketch, $p);
            push @params, $filled;
        }

        $bundle = $b if $params_ok;
    }

    return (undef, "No bundle in the $sketch api matched the given parameters")
     unless $bundle;

    $api->log3("Verified sketch %s entry: filled parameters are %s",
               $sketch, \@params);

    my $activation_id = sprintf('__%03d %s %s',
                                $activation_position++,
                                $found->name(),
                                $bundle);

    $activation_id =~ s/\W+/_/g;

    return DCAPI::Activation->new(api => $api,
                                  sketch => $found,
                                  environment => $env,
                                  bundle => $bundle,
                                  id => $activation_id,
                                  params => \@params);
}

sub fill_param
{
    my $api    = shift;
    my $name   = shift;
    my $type   = shift;
    my $params = shift;
    my $extra  = shift;

    if ($type eq 'environment')
    {
        return {set=>undef, type => $type, name => $name, value => $extra->{environment}};
    }

    foreach my $pkey (sort keys %$params)
    {
        my $pval = $params->{$pkey};
        if (!exists $pval->{$name} && exists $extra->{default})
        {
            $pval->{$name} = $extra->{default};
        }

        # TODO: add more parameter types and validate the value!!!
        if ($type eq 'array' && exists $pval->{$name} && ref $pval->{$name} eq 'HASH')
        {
            return {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
        }
        elsif ($type eq 'string' && exists $pval->{$name} && Util::is_scalar($pval->{$name}))
        {
            return {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
        }
        elsif ($type eq 'boolean' && exists $pval->{$name} && Util::is_scalar($pval->{$name}))
        {
            return {set=>$pkey, type => $type, name => $name, value => 0+!!$pval->{$name}};
        }
        elsif ($type eq 'list' && exists $pval->{$name} && ref $pval->{$name} eq 'ARRAY')
        {
            return {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
        }
    }

    return;
}

sub can_inline
{
    my $self = shift @_;
    my $type = shift @_;

    return ($type ne 'list' && $type ne 'array');
}

sub make_bundle_params
{
    my $self = shift @_;

    my @data;
    foreach my $p (@{$self->params()})
    {
        if ($self->can_inline($p->{type}))
        {
            foreach my $pr (Util::recurse_print($p->{value}, '', 0, 0))
            {
                push @data, $pr->{value};
            }
        }
        elsif ($p->{type} eq 'array')
        {
            push @data, sprintf('"default:cfsketch_g.%s_%s"', $self->id(), $p->{name});
        }
        elsif ($p->{type} eq 'list')
        {
            push @data, sprintf('@(cfsketch_g.%s_%s)', $self->id(), $p->{name});
        }
    }

    return join(', ', @data);;
}

sub data_dump
{
    my $self = shift @_;

    return {
            sketch => $self->sketch()->data_dump(),
            environment => $self->environment(),
            bundle => $self->bundle(),
            params => $self->params(),
            id => $self->id(),
           };
}

1;
