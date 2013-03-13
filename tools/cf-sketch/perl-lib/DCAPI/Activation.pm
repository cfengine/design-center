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
    my %bundle_params;
    my $activation_id;

    foreach my $b (@bundles_to_check)
    {
        $bundle_params{$b} = [];
        $activation_id = sprintf('__%03d %s %s',
                                 $activation_position,
                                 $found->name(),
                                 $b);

        $activation_id =~ s/\W+/_/g;

        my $sketch_api = $found->api()->{$b};

        my $params_ok = 1;
        foreach my $p (@$sketch_api)
        {
            $api->log5("Checking the API of sketch %s, bundle %s: parameter %s", $sketch, $b, $p);
            my %extra = (
                         environment => $env,
                         sketch => $found,
                         sketch_name => $found->name(),
                         bundle => $b,
                         id => $activation_id,
                         uses => $api->uses(),
                        );

            $extra{default} = $p->{default} if exists $p->{default};

            my $filled = fill_param($api,
                                    $p->{name},
                                    $p->{type},
                                    \@param_sets,
                                    \%extra);
            unless ($filled)
            {
                $api->log4("The API of sketch %s, bundle %s did not match parameter %s", $sketch, $b, $p);
                $params_ok = 0;
                last;
            }

            $api->log5("The API of sketch %s, bundle %s matched parameter %s + default %s => %s", $sketch, $b, $p, $extra{default}||'""', $filled);
            push @{$bundle_params{$b}}, $filled;
        }

        if ($params_ok)
        {
            $bundle = $b;
            last;
        }
    }

    return (undef, "No bundle in the $sketch api matched the given parameters")
     unless $bundle;

    $activation_position++;

    $api->log3("Verified sketch %s, bundle %s: filled parameters are %s",
               $sketch, $bundle, $bundle_params{$bundle});

    return DCAPI::Activation->new(api => $api,
                                  sketch => $found,
                                  environment => $env,
                                  bundle => $bundle,
                                  id => $activation_id,
                                  params => $bundle_params{$bundle});
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
        return { bundle => $extra->{bundle}, sketch => $extra->{sketch_name},
                 set=>undef,
                 type => $type, name => $name, value => $extra->{environment}};
    }

    if ($type eq 'return')
    {
        return { bundle => $extra->{bundle}, sketch => $extra->{sketch_name},
                 set=>undef,
                 type => $type, name => $name, value => undef};
    }

    if ($type eq 'metadata')
    {
        return { bundle => $extra->{bundle}, sketch => $extra->{sketch_name},
                 set=>'sketch metadata',
                 type => 'array', name => $name, value => $extra->{sketch}->runfile_data_dump()};
    }

    my @uses;
    if (defined $extra->{uses})
    {
        @uses = @{$extra->{uses}};
    }

    my $ret;
    foreach my $pset (@$param_sets)
    {
        my ($pkey, $pval_ref) = @$pset;
        # Get the values locally so overwriting them with the default doesn't
        # set them for the future.  This was a fun bug to hunt.
        my %pval = %$pval_ref;
        if (!exists $pval{$name} && exists $extra->{default})
        {
            $extra->{default} =~ s/__PREFIX__/$extra->{id}/g;
            $pval{$name} = $extra->{default};
        }

        # TODO: add more parameter types and validate the value!!!
        if ($type eq 'array' && exists $pval{$name} && ref $pval{$name} eq 'HASH')
        {
            if (defined $ret)           # merge arrays
            {
                my $oldval = $ret->{value};
                my $newval = $pval{$name};
                $ret = {set=>$pkey, type => $type, name => $name, value => Util::hashref_merge($oldval, $newval)};
            }
            else
            {
                $ret = {set=>$pkey, type => $type, name => $name, value => $pval{$name}};
            }
        }
        elsif ($type eq 'string' && exists $pval{$name} && Util::is_scalar($pval{$name}))
        {
            $ret = {set=>$pkey, type => $type, name => $name, value => $pval{$name}};
        }
        elsif ($type eq 'boolean' && exists $pval{$name} && Util::is_scalar($pval{$name}))
        {
            $ret = {set=>$pkey, type => $type, name => $name, value => 0+!!$pval{$name}};
        }
        elsif ($type eq 'list' && exists $pval{$name} && ref $pval{$name} eq 'ARRAY')
        {
            $ret = {set=>$pkey, type => $type, name => $name, value => $pval{$name}};
        }
    }

    unless (defined $ret)
    {
        foreach my $use (@uses)
        {
            # { destination_sketch: "CFEngine::sketch_template",
            # destination_list: "mylist", source_sketch: "VCS::vcs_mirror",
            # source_scalar: "deploy_path" }

            # TODO maybe: add destination_scalar key
            my $d = Util::hashref_search($use, 'destination_sketch') || 'destination_sketch not given';
            my $dlist = Util::hashref_search($use, 'destination_list') || 'destination_list not given';
            my $dbundle = Util::hashref_search($use, 'destination_bundle');

            $api->log5("Looking for a 'use' match for %s parameter %s in sketch %s, bundle %s",
                       $type, $name, $extra->{sketch_name}, $extra->{bundle});

            # check the optional destination_bundle specifier
            next if (defined $dbundle && $dbundle ne $extra->{bundle});
            # check the mandatory destination_sketch
            next if $d ne $extra->{sketch_name};
            # check the mandatory destination_list
            next if ($dlist ne $name || $type ne 'list');

            $api->log4("Found a 'use' match for list parameter %s in sketch %s, bundle %s: %s",
                       $name, $d, $extra->{bundle}, $use);

            $ret = {set=>'use', type => $type, name => $name, deferred_value => $use};
        }
    }

    if (defined $ret && ref $ret eq 'HASH')
    {
        $ret->{bundle} = $extra->{bundle};
        $ret->{sketch} = $extra->{sketch_name};
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
            push @data, sprintf('"default:cfsketch_run.%s_%s"', $self->id(), $p->{name});
        }
        elsif ($p->{type} eq 'list')
        {
            push @data, sprintf('@(cfsketch_run.%s_%s)', $self->id(), $p->{name});
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


sub resolve_now
{
    my $self = shift @_;
    my $all = shift @_;

 MYPARAM:
    foreach my $param (@{$self->params()})
    {
        my $defer = $param->{deferred_value};
        next unless defined $defer;
        $self->api()->log4("Resolving deferred parameter %s", $param);
    ACTIVATION:
        foreach my $a (@$all)
        {
        USE:
            foreach my $use (@{$self->api()->uses()})
            {
            APARAM:
                foreach my $aparam (@{$a->params()})
                {
                    my $s = Util::hashref_search($use, 'source_sketch') || 'source_sketch not given';
                    my $scalar = Util::hashref_search($use, 'source_scalar') || 'source_scalar not given';
                    my $sbundle = Util::hashref_search($use, 'source_bundle');

                    next APARAM if exists $aparam->{deferred_value};

                    # check the optional source_bundle specifier
                    next APARAM if (defined $sbundle && $sbundle ne $aparam->{bundle});
                    # check the mandatory source_sketch
                    next APARAM if $s ne $aparam->{sketch};
                    # check the mandatory source_scalar
                    $self->api()->log4("checking deferred parameter %s: %s", $scalar, $aparam);
                    next APARAM if ($scalar ne $aparam->{name} ||
                                    'return' ne $aparam->{type});

                    $self->api()->log4("Found a 'use' match for deferred parameter %s: %s matches %s",
                                       $param, $use, $aparam);

                    # NOTE: this is directly linked to the name of the return
                    # array in DCAPI.pm!!!
                    push @{$param->{value}}, sprintf('$(return_%s[%s])',
                                                     $a->id(), $scalar);
                }
            }
        }

        return (0, "Could not resolve deferred parameter $param->{name}")
         unless defined $param->{value};
    }

    return 1;
}

1;
