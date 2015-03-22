package DCAPI::Activation;

use strict;
use warnings;

use Mo qw/default build builder is required option/;

has api => ( is => 'ro', required => 1 );

has sketch => ( is => 'ro', required => 1 );
has environment => ( is => 'ro', required => 1 );
has bundle => ( is => 'ro', required => 1 );
has params => ( is => 'ro', required => 1 );
has metadata => ( is => 'ro', required => 1 );
has prefix => ( is => 'ro', required => 0, default => '' );
has compositions => ( is => 'ro', required => 1, default => [] );
has id => ( is => 'ro', required => 1 );
has priority => ( is => 'ro', required => 1 );
has hash => ( is => 'ro', required => 1 );

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

    my $activation_prefix  = $spec->{identifier} || '';

    my $compositions = $spec->{compositions} || [];

    if (ref $compositions ne 'ARRAY')
    {
        return (undef, "Invalid compositions parameter");
    }

    my $metadata = $spec->{metadata} || {};

    if (ref $metadata ne 'HASH')
    {
        return (undef, "Invalid metadata parameter");
    }

    my $found;
    my @repos;
    my $target = glob($spec->{target});
    foreach my $repo (map { $api->load_repo($_) } @{$api->repos()})
    {
        if ($target)
        {
            next if $target ne $repo->location();
        }

        push @repos, $repo;
    }

    $api->log4("Activation of sketch %s will be done against candidate repos %s",
               $sketch,
               [map { $_->location() } @repos]);

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

    my $activation_priority = Util::hashref_search($spec, qw/priority/) || '1';

    my $activation_id;

    foreach my $b (@bundles_to_check)
    {
        $bundle_params{$b} = [];
        $activation_id = sprintf('__%s_%03d %s %s',
                                 $activation_prefix,
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
                         timestamp => 'notime', # we only take a timestamp externally
                         compositions => $compositions,
                         metadata => $metadata,
                         available_compositions => $api->compositions(),
                         pdef => $p,
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

    my $bundle_options = $found->api_options($bundle);
    if ($bundle_options->{single_use})
    {
        # define behavior for single-use sketches: Redmine #2534
    }

    my %cparams;
    foreach my $p (@{$bundle_params{$bundle}})
    {
        next unless sketch_parameter_type($p->{type});
        next if $p->{name} =~ m/metadata/;
        $cparams{$p->{name}} = $p->{value};
    }

    $cparams{$sketch} = $bundle;
    # note we don't include the "runenv" above but add it here, because some sketches don't have a "runenv" parameter
    $cparams{env} = $env;

    $api->log5("sketch %s, bundle %s gets parameters %s", $sketch, $bundle, \%cparams);

    return DCAPI::Activation->new(api => $api,
                                  prefix => $activation_prefix,
                                  sketch => $found,
                                  environment => $env,
                                  bundle => $bundle,
                                  id => $activation_id,
                                  priority => $activation_priority,
                                  compositions => $compositions,
                                  metadata => $metadata,
                                  params => $bundle_params{$bundle},
                                  hash => Util::md5($api->cencode(\%cparams)));
}

sub fill_param
{
    my $api        = shift;
    my $name       = shift;
    my $type       = shift;
    my $param_sets = shift;
    my $extra      = shift;

    $api->log5("looking to fill parameter $name of type $type");

    if (environment_type($type))
    {
        return { bundle => $extra->{bundle}, sketch => $extra->{sketch_name},
                 set=>undef,
                 type => $type, name => $name, value => $extra->{environment}};
    }

    if (options_type($type))
    {
        return { bundle => $extra->{bundle}, sketch => $extra->{sketch_name},
                 set=>undef,
                 type => $type, name => $name,
                 value => $extra->{sketch}->api_options($extra->{bundle}),
               };
    }

    if (return_type($type))
    {
        return { bundle => $extra->{bundle}, sketch => $extra->{sketch_name},
                 set=>undef,
                 type => $type, name => $name, value => undef};
    }

    if ($type eq 'metadata')
    {
        my $metadata = $extra->{sketch}->runfile_data_dump();
        $metadata = Util::hashref_merge($metadata,
                                        {
                                         activation => $extra->{metadata},
                                         bundle_options => $extra->{sketch}->api_options($extra->{bundle}),
                                         api => $extra->{sketch}->api_describe($extra->{bundle}),
                                        },
                                        {
                                         activation => {
                                                        identifier => $extra->{id},
                                                        timestamp => $extra->{timestamp},
                                                       },
                                        });

        return { bundle => $extra->{bundle}, sketch => $extra->{sketch_name},
                 set=>'sketch metadata',
                 type => 'array', name => $name, value => $metadata };
    }

    my @compositions;
    my %available_compositions;
    if (defined $extra->{compositions})
    {
        @compositions = @{$extra->{compositions}};
    }

    if (defined $extra->{available_compositions})
    {
        %available_compositions = %{$extra->{available_compositions}};
    }

    my @filtered_param_sets;
    foreach my $pset (@$param_sets)
    {
        my $pset_value = $pset->[1];
        if (ref $pset_value ne 'HASH')
        {
            $api->log("skipping invalid parameter set: %s",
                      $pset);
        }
        else
        {
            my $specific_bundle = $pset_value->{__bundle__};
            if (defined $specific_bundle && $specific_bundle ne $extra->{bundle})
            {
                 $api->log("skipping parameter set because __bundle__ parameter '%s' was specified and doesn't match our bundle '%s'",
                           $specific_bundle,
                           $extra->{bundle});
            }
            else
            {
                 push @filtered_param_sets, $pset;
            }
        }
    }

    my $ret;
    foreach my $pset (@filtered_param_sets)
    {
        my $defaulted = 0;
        my ($pkey, $pval_ref) = @$pset;
        # Get the values locally so overwriting them with the default doesn't
        # set them for the future.  This was a fun bug to hunt.
        my %pval = %$pval_ref;
        if (!exists $pval{$name} && exists $extra->{default})
        {
            $extra->{default} =~ s/__PREFIX__/$extra->{id}/g;
            $pval{$name} = $extra->{default};
            $defaulted = 1;
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
        elsif ($type eq 'array' && exists $pval{$name} && ref $pval{$name} eq 'ARRAY')
        {
            my %mapped = map { sprintf('%06d', $_) => $pval{$name}->[$_] } 0 .. scalar @{$pval{$name}} - 1;
            if (defined $ret)           # merge arrays
            {
                my $oldval = $ret->{value};
                my $newval = \%mapped;
                $ret = {set=>$pkey, type => $type, name => $name, value => Util::hashref_merge($oldval, $newval)};
            }
            else
            {
                $ret = {set=>$pkey, type => $type, name => $name, value => \%mapped};
            }
        }
        elsif ($type eq 'string' && exists $pval{$name} &&
               (Util::is_scalar($pval{$name}) || Util::is_funcall($pval{$name})))
        {
            my $choice = Util::hashref_search($extra, qw/pdef choice/);
            $ret = {set=>$pkey, type => $type, name => $name, value => $pval{$name}};
            if (defined $choice && ref $choice eq 'ARRAY')
            {
                unless (grep { $_ eq $pval{$name} } @$choice)
                {
                    $api->log("For %s parameter %s, choice %s didn't fit offered value %s",
                              $extra->{bundle}, $name, $choice, $pval{$name});
                    undef $ret;
                }
            }

        }
        # TODO: should booleans accept funcalls?  hmm....
        elsif ($type eq 'boolean' && exists $pval{$name} && Util::is_scalar($pval{$name}))
        {
            $ret = {set=>$pkey, type => $type, name => $name, value => 0+!!$pval{$name}};
        }
        elsif ($type eq 'list' && exists $pval{$name} && ref $pval{$name} eq 'ARRAY')
        {
            $ret = {set=>$pkey, type => $type, name => $name, value => $pval{$name}};
        }

        $ret->{defaulted} = $defaulted
         if $ret;
    }

    if (!defined $ret || $ret->{defaulted})
    {
        foreach my $compose_key (@compositions)
        {
            next unless exists $available_compositions{$compose_key};
            my $compose = $available_compositions{$compose_key};
            next if ($ret && !$ret->{defaulted});

            # { destination_sketch: "CFEngine::sketch_template",
            # destination_list: "mylist", source_sketch: "VCS::vcs_mirror",
            # source_scalar: "deploy_path" }

            my $d = Util::hashref_search($compose, 'destination_sketch') || 'destination_sketch not given';
            my $dlist = Util::hashref_search($compose, 'destination_list') || 'destination_list not given';
            my $dscalar = Util::hashref_search($compose, 'destination_scalar') || 'destination_scalar not given';
            my $dbundle = Util::hashref_search($compose, 'destination_bundle');

            $api->log3("Looking for a 'compose' match for %s parameter %s in sketch %s, bundle %s: %s",
                       $type, $name, $extra->{sketch_name}, $extra->{bundle}, $compose);

            # check the optional destination_bundle specifier
            next if (defined $dbundle && $dbundle ne $extra->{bundle});
            # check the mandatory destination_sketch
            next if $d ne $extra->{sketch_name};
            # check the mandatory destination_list
            if ($dlist eq $name && $type eq 'list')
            {
                $api->log4("Found a 'compose' match for list parameter %s in sketch %s, bundle %s: %s=%s",
                           $name, $d, $extra->{bundle}, $compose_key, $compose);
                $ret = {set=>'compose', type => $type, name => $name, deferred_value => $compose, deferred_list => 0, defaulted => 0};
            }
            # TODO: maybe support other types
            elsif ($dscalar eq $name && $type eq 'string')
            {
                $api->log4("Found a 'compose' match for scalar parameter %s in sketch %s, bundle %s: %s=%s",
                           $name, $d, $extra->{bundle}, $compose_key, $compose);
                $ret = {set=>'compose', type => $type, name => $name, deferred_value => $compose, deferred_list => 0, defaulted => 0};
            }
            else
            {
                $api->log4("There was no 'compose' match for parameter %s in sketch %s, bundle %s",
                           $name, $d, $extra->{bundle});
            }
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
    my $type = shift @_;

    return 0 if ignored_type($type);

    return ! container_type($type);
}

sub ignored_type
{
    my $type = shift @_;

    return return_type($type) || options_type($type);
}

sub options_type
{
    my $type = shift @_;

    return $type eq 'bundle_options';
}

sub environment_type
{
    my $type = shift @_;

    return $type eq 'environment';
}

sub container_type
{
    my $type = shift @_;

    return (
            $type eq 'list' ||
            $type eq 'array' ||
            $type eq 'metadata'
           );
}

sub sketch_parameter_type
{
    my $type = shift @_;

    return 1 if container_type($type);
    return 0 if environment_type($type);
    return can_inline($type);
}

sub return_type
{
    my $type = shift @_;

    return $type eq 'return';
}

sub make_bundle_params
{
    my $self = shift @_;
    my $indent = shift @_;
    my $a = shift @_;

    my @data;
    foreach my $p (@{$self->params()})
    {
        if (ignored_type($p->{type}))
        {
            $self->api()->log5("Bundle parameters: ignoring parameter %s", $p);
        }
        elsif (environment_type($p->{type}))
        {
            push @data, sprintf('@(cfsketch_run.%s)', $p->{value});
        }
        elsif (can_inline($p->{type}))
        {
            foreach my $pr (Util::recurse_print($p->{value}, '', 0, 0, $p->{type} eq 'boolean'))
            {
                push @data, $pr->{value};
            }
        }
        elsif (container_type($p->{type}))
        {
            push @data, sprintf('@(cfsketch_run.%s_%s)', $a->id(), $p->{name});
        }
        else # nothing should reach this point
        {
            $self->api()->log("Bundle parameters: can't handle parameter %s", $p);
            push @data, sprintf('"baddata"');
        }
    }

    return join(",$indent", @data);;
}

sub data_dump
{
    my $self = shift @_;

    return {
            sketch => $self->sketch()->data_dump(),
            environment => $self->environment(),
            bundle => $self->bundle(),
            params => $self->params(),
            compositions => $self->compositions(),
            prefix => $self->prefix(),
            metadata => $self->metadata(),
            id => $self->id(),
            hash => $self->hash(),
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
        COMPOSE:
            foreach my $compose_key (@{$self->compositions()})
            {
                my $compose = $self->api()->compositions()->{$compose_key};
                next COMPOSE unless defined $compose;
                my $activation_regex = Util::hashref_search($compose, 'activation');
                # check the optional activation regex... TODO: maybe make this more involved
                next COMPOSE if (defined $activation_regex && $a->id() !~ m/$activation_regex/);

            APARAM:
                foreach my $aparam (@{$a->params()})
                {
                    my $s = Util::hashref_search($compose, 'source_sketch') || 'source_sketch not given';
                    my $sbundle = Util::hashref_search($compose, 'source_bundle');
                    my $scalar = Util::hashref_search($compose, 'source_scalar') || 'source_scalar not given';

                    next APARAM if exists $aparam->{deferred_value};

                    # check the optional source_bundle specifier
                    next APARAM if (defined $sbundle && $sbundle ne $aparam->{bundle});
                    # check the mandatory source_sketch
                    next APARAM if $s ne $aparam->{sketch};
                    # check the mandatory source_scalar
                    $self->api()->log4("checking deferred parameter %s: %s", $scalar, $aparam);
                    next APARAM if ($scalar ne $aparam->{name} ||
                                    'return' ne $aparam->{type});

                    $self->api()->log4("Found a 'compose' match for deferred parameter %s: %s=%s matches %s",
                                       $param, $compose_key, $compose, $aparam);

                    # NOTE: this is directly linked to the name of the return
                    # array in DCAPI.pm!!!
                    if ($param->{deferred_list})
                    {
                        push @{$param->{value}}, sprintf('$(cfsketch_run.return_%s[%s])',
                                                         $a->id(), $scalar);
                    }
                    else # deferred scalar for scalar to scalar mapping
                    {
                        $param->{value} = sprintf('$(cfsketch_run.return_%s[%s])',
                                                  $a->id(), $scalar);
                    }
                }
            }
        }

        return (0, "Could not resolve deferred parameter $param->{name}")
         unless defined $param->{value};
    }

    return 1;
}

1;
