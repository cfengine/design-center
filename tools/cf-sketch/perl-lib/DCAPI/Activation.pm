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

    my @param_sets;
    foreach (@$params)
    {
        return (undef, "The activation params '$_' have not been defined")
        unless exists $api->definitions()->{$_};

        return (undef, "The activation params '$_' do not apply to sketch $sketch")
        unless exists $api->definitions()->{$_}->{$sketch};

        push @param_sets, [$_, $api->definitions()->{$_}->{$sketch}];
    }

    $api->log3("Verified sketch %s activation: run environment %s and params %s",
               $sketch, $env, $params);

    $api->log4("Checking sketch %s: API %s versus extracted parameters %s",
               $sketch,
               $found->api(),
               \@param_sets);

    my @bundles_to_check = sort keys %{$found->api()};

    # look at the specific bundle if requested
    if (exists $spec->{bundle} &&
        defined $spec->{bundle}) {
        @bundles_to_check = grep { $_ eq $spec->{bundle}} @bundles_to_check;
    }

    my $bundle;
    my @bundle_params;
    my $activation_id;

    foreach my $b (@bundles_to_check)
    {
        $activation_id = sprintf('__%03d %s %s',
                                 $activation_position,
                                 $found->name(),
                                 $b);

        $activation_id =~ s/\W+/_/g;

        my $sketch_api = $found->api()->{$b};

        my $params_ok = 1;
        foreach my $p (@$sketch_api)
        {
            $api->log5("Checking the API of sketch %s: parameter %s", $sketch, $p);
            my $filled = fill_param($api,
                                    $p->{name}, $p->{type}, \@param_sets,
                                    {
                                     environment => $env,
                                     sketch => $found,
                                     id => $activation_id,
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
            push @bundle_params, $filled;
        }

        $bundle = $b if $params_ok;
    }

    return (undef, "No bundle in the $sketch api matched the given parameters")
     unless $bundle;

    $activation_position++;

    $api->log3("Verified sketch %s entry: filled parameters are %s",
               $sketch, \@bundle_params);

    return DCAPI::Activation->new(api => $api,
                                  sketch => $found,
                                  environment => $env,
                                  bundle => $bundle,
                                  id => $activation_id,
                                  params => \@bundle_params);
}

sub fill_param
{
    my $api        = shift;
    my $name       = shift;
    my $type       = shift;
    my $param_sets = shift;
    my $extra      = shift;

    if ($type eq 'environment')
    {
        return {set=>undef, type => $type, name => $name, value => $extra->{environment}};
    }

    if ($type eq 'return')
    {
        return {set=>undef, type => $type, name => $name, value => undef};
    }

    if ($type eq 'metadata')
    {
        return {set=>'sketch metadata', type => 'array', name => $name, value => $extra->{sketch}->runfile_data_dump()};
    }

    my $ret;
    foreach my $pset (@$param_sets)
    {
        my ($pkey, $pval) = @$pset;
        if (!exists $pval->{$name} && exists $extra->{default})
        {
            $extra->{default} =~ s/__PREFIX__/$extra->{id}/g;
            $pval->{$name} = $extra->{default};
        }

        # TODO: add more parameter types and validate the value!!!
        if ($type eq 'array' && exists $pval->{$name} && ref $pval->{$name} eq 'HASH')
        {
            if (defined $ret)           # merge arrays
            {
                my $oldval = $ret->{value};
                my $newval = $pval->{$name};
                $ret = {set=>$pkey, type => $type, name => $name, value => Util::hashref_merge($oldval, $newval)};
            }
            else
            {
                $ret = {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
            }
        }
        elsif ($type eq 'string' && exists $pval->{$name} && Util::is_scalar($pval->{$name}))
        {
            $ret = {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
        }
        elsif ($type eq 'boolean' && exists $pval->{$name} && Util::is_scalar($pval->{$name}))
        {
            $ret = {set=>$pkey, type => $type, name => $name, value => 0+!!$pval->{$name}};
        }
        elsif ($type eq 'list' && exists $pval->{$name} && ref $pval->{$name} eq 'ARRAY')
        {
            $ret = {set=>$pkey, type => $type, name => $name, value => $pval->{$name}};
        }
    }

    return $ret;
}

sub can_inline
{
    my $self = shift @_;
    my $type = shift @_;

    return (!$self->ignored_type($type) &&
            ($type ne 'list' && $type ne 'array' &&
             $type ne 'metadata'));
}

sub ignored_type
{
    my $self = shift @_;
    my $type = shift @_;

    return ($type eq 'return');
}

sub make_bundle_params
{
    my $self = shift @_;

    my @data;
    foreach my $p (@{$self->params()})
    {
        if ($self->ignored_type($p->{type}))
        {
            $self->api()->log5("Bundle parameters: ignoring parameter %s", $p);
        }
        elsif ($self->can_inline($p->{type}))
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
