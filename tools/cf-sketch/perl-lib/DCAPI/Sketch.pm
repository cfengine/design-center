package DCAPI::Sketch;

use strict;
use warnings;

use DCAPI::Terms;

use Util;
use Mo qw/default build builder is required option/;

use constant MEMBERS => qw/entry_point interface manifest metadata api namespace/;
use constant META_MEMBERS => qw/name version description license tags depends authors/;

has dcapi        => ( is => 'ro', required => 1 );
has repo         => ( is => 'ro', required => 1 );
has desc         => ( is => 'ro', required => 1 );
has describe     => ( is => 'rw' );
has location     => ( is => 'ro', required => 1 );
has rel_location => ( is => 'ro', required => 1 );
has verify_files => ( is => 'ro', required => 1 );

# sketch-specific properties
has api         => ( is => 'rw' );
has namespace   => ( is => 'rw' );
has entry_point => ( is => 'rw' );
has interface   => ( is => 'rw' );
has library     => ( is => 'rw', default => sub { 0 } );

has manifest    => ( is => 'rw', default => sub { {} } );
has metadata    => ( is => 'rw', default => sub { {} } );

sub BUILD
{
    my $self = shift;

    my ($config, $reason) = $self->dcapi()->load($self->desc());
    die sprintf("Sketch in location %s could not initialize ($reason) from data %s\n",
                $self->location(),
                $self->desc()||'')
    unless defined $config;

    $self->describe($config);

    my $metadata = Util::hashref_search($config, 'metadata');

    foreach my $m (MEMBERS())
    {
        my $v = Util::hashref_search($config, $m);
        unless (defined $v)
        {
            if ($m eq 'entry_point')
            {
                $self->library(1);
            }
            elsif ($m eq 'namespace')
            {
                # it's OK to have a null namespace, it becomes "default"
            }
            else
            {
                die sprintf("Sketch in location %s is missing required attribute: %s\n",
                            $self->location(),
                            $m);
            }
        }

        $self->$m($v);
    }

    $self->namespace('default') unless $self->namespace();

    if ($self->verify_files())
    {
        my $manifest = $self->manifest();
        my $name = $self->name();

        foreach my $f (sort keys %$manifest)
        {
            my $file = sprintf("%s/%s", $self->location(), $f);
            die "Sketch $name is missing manifest file $file" unless -f $file;
        }
    }
}

# yeah it's a hack, but better than AUTOLOAD
# define a metadata accessor for each keyword in META_MEMBERS
foreach my $mm ( META_MEMBERS() )
{
    my $method_name = __PACKAGE__ . '::' . $mm;
    no strict 'refs';
    *{$method_name} = sub
    {
        my $self = shift @_;
        if (scalar @_)
        {
            $self->metadata()->{$mm} = shift;
        }

        return $self->metadata()->{$mm};
    };
}

sub data_dump
{
    my $self = shift;
    my $flatten = shift;

    my %ret = (
               map { $_ => $self->$_ } MEMBERS()
              );
    if ($flatten)
    {
        foreach my $mkey (META_MEMBERS())
        {
            $ret{$mkey} = $ret{metadata}->{$mkey}
            if exists $ret{metadata}->{$mkey};
        }
    }

    return \%ret;
}

sub runfile_data_dump
{
    my $self = shift;

    my %ret;
    foreach my $m (sort qw/authors tags version name license location/)
    {
        $ret{$m} = $self->$m();
    }

    # only dependencies with :: are useful
    my %depends = defined $self->depends() ? %{$self->depends()} : ();
    $ret{depends} = [ grep { $_ =~ m/::/ } sort keys %depends ];

    my %manifest = defined $self->manifest() ? %{$self->manifest()} : ();
    my @manifest = sort keys %manifest;
    $ret{manifest} = \@manifest;
    $ret{manifest_cf} = [ grep { $_ =~ m/\.cf$/ } @manifest ];
    $ret{manifest_docs} = [ grep { $self->manifest()->{$_}->{documentation} } @manifest ];
    $ret{manifest_exe} = [ grep {
        exists $self->manifest()->{$_}->{perm} &&
        (oct($self->manifest()->{$_}->{perm}) & 0111)
    } @manifest ];

    my %known = map { $_ => 1 } (@{$ret{manifest_cf}}, @{$ret{manifest_exe}}, @{$ret{manifest_docs}});
    $ret{manifest_extra} = [ grep { !exists $known{$_} } @manifest ];

    return \%ret;
}

sub make_readme
{
    my $self = shift;

    # describe sketch metadata
    my $readme = <<EOHIPPUS;
# {{name}} version {{version}}

License: {{license}}
Tags: {{tags}}
Authors: {{authors}}

## Description
{{description}}

## Dependencies
{{depends}}

## API
{{parameters}}

## SAMPLE USAGE
See `test.cf` or the example parameters provided

EOHIPPUS

    my %data = %{$self->data_dump(1)};

    $data{authors} = join ", ", @{$data{authors}};
    $data{tags} = join ", ", @{$data{tags}};
    $data{depends} = (join ", ", sort(grep(/::/, keys %{$data{depends}})))||'none';

    # api:
    # {
    #     // the key is the name of the bundle!
    #     ping:
    #     [
    #         { type: "environment", name: "runenv", },
    #         { type: "metadata", name: "metadata", },
    #         { type: "list", name: "hosts" },
    #         { type: "string", name: "count" },
    #         { type: "return", name: "reached", },
    #         { type: "return", name: "not_reached", },
    #     ],
    # },
    my @p;
    foreach my $bundle (sort keys %{$data{api}})
    {
        my $spec = $data{api}->{$bundle};
        push @p, "### bundle: $bundle";
        foreach my $param (@$spec)
        {
            my $return = DCAPI::Activation::return_type($param->{type});
            if (DCAPI::Activation::options_type($param->{type}))
            {
                my $options = $self->api_options($bundle);
                foreach my $k (keys %$options)
                {
                    push @p, "* bundle option: $k = " . $options->{$k} . "\n";
                }
            }
            else
            {
                push @p, sprintf("* %s _%s_ *%s* (default: %s, description: %s)\n",
                                 $return ? 'returns' : 'parameter',
                                 $param->{type},
                                 $param->{name},
                                 (exists $param->{default} ? '`'.(defined $param->{default} ? $self->dcapi()->encode($param->{default}):'null').'`' : 'none'),
                                 (defined $param->{description} ? $param->{description} : 'none'));
            }
        }
    }

    $data{parameters} = (join "\n", @p)||'none';

    foreach my $k (keys %data)
    {
        $readme =~ s/\{\{(\w+)\}\}/(defined $data{$1} ? $data{$1} : "UNDEFINED:$1")/eg;
    }

    $self->dcapi()->log4("Generated README:\n$readme\n");
    return $readme;
}

sub api_options
{
    my $self = shift;
    my $bundle = shift;

    my $bundle_api = Util::hashref_search($self->api(), $bundle);
    return {} unless $bundle_api;

    foreach my $param (@$bundle_api)
    {
        my $type = Util::hashref_search($param, 'type');
        next unless ($type && $type eq 'bundle_options');
        my %options = %$param;
        delete $options{type};
        return \%options;
    }

    return {};
}

sub matches
{
    my $self = shift;
    my $term_data = shift;

    my $terms = DCAPI::Terms->new(api => $self->dcapi(),
                                  terms => $term_data);

    my $my_data = $self->data_dump(1); # flatten it
    my $ok = $terms->matches($my_data);

    $self->dcapi()->log_int($ok ? 4:5,
                            "sketch %s %s terms %s",
                            $self->name,
                            $ok ? 'matched' : 'did not match',
                            $term_data);
    return $ok;
}

sub equals
{
    my $self = shift;
    my $other = shift @_;

    return (ref $self eq ref $other &&
            $self->name() eq $other->name() &&
            $self->version() eq $other->version());
}

sub get_inputs
{
    my $self = shift;
    my $relocate = shift;
    my $recurse = shift;

    my @inputs;
    if ($recurse)
    {
        my $depcheck = $self->resolve_dependencies(install => 0);
        if ($depcheck->success())
        {
            foreach my $dep (keys %{$depcheck->data()})
            {
                $self->dcapi()->log5("Sketch %s looking for dependency %s",
                                     $self->name(),
                                     $dep);
                my $sketch = $self->dcapi()->describe_int($dep, undef, 1);
                if ($sketch)
                {
                    # we decrement the recurse to avoid circular dependencies
                    push @inputs, $sketch->get_inputs($relocate, $recurse-1);
                }
                else
                {
                    $self->dcapi()->log("Sketch %s could not find dependency %s",
                                        $self->name(),
                                        $dep);
                }
            }
        }
    }

    my $i = 'ARRAY' eq ref $self->interface() ? $self->interface() : [$self->interface()];
    my $location = $relocate ? "$relocate/" . $self->rel_location() : $self->location();
    push @inputs, map { "$location/$_" } @$i;

    return @inputs;
}

sub resolve_dependencies
{
    my $self = shift @_;
    my %options = @_;

    my $result = DCAPI::Result->new(api => $self->dcapi(),
                                    status => 1,
                                    success => 1,
                                    data => { });

    my %ret;
    my %deps;
    %deps = %{$self->depends()} if ref $self->depends() eq 'HASH';
    my $name = $self->name();

    foreach my $dep (sort keys %deps)
    {
        $self->dcapi()->log5("Checking sketch $name dependency %s", $dep);
        if ($dep eq 'os')
        {
            $self->dcapi()->log2("Ignoring sketch $name OS dependency %s", $dep);
        }
        elsif ($dep eq 'cfengine')
        {
            if (exists $deps{$dep}->{version})
            {
                my $v = $deps{$dep}->{version};
                if ($self->dcapi()->is_ok_cfengine_version($v))
                {
                    $self->dcapi()->log3("CFEngine version requirement of sketch $name OK: %s", $v);
                }
                else
                {
                    $self->dcapi()->log2("CFEngine version requirement of sketch $name not OK: %s", $v);
                    return $result->add_error('dependency',
                                              "CFEngine version below required $v for sketch $name");
                }
            }
        }
        else                    # anything else is a sketch name...
        {
            my %install_request = ( sketch => $dep, target => $options{target}, force => $options{force} );
            my @criteria = (["name", "equals", $dep]);
            if (exists $deps{$dep}->{version})
            {
                push @criteria, ["version", ">=", $deps{$dep}->{version}];
            }

            my $list = $self->dcapi()->list_int($self->dcapi()->repos(),
                                                \@criteria,
                                                { flatten => 1 });
            if (scalar @$list < 1 || $options{force})
            {
                if ($options{install})
                {
                    # try to install the dependency
                    my $search = $self->dcapi()->search(\@criteria);
                    my $installed = 0;
                    if ($search->success())
                    {
                        my $sdata = Util::hashref_search($search->data(), 'search') || {};

                        foreach my $srepo (sort keys %$sdata)
                        {
                            $install_request{source} = $srepo;
                            $self->dcapi()->log("Trying to install dependency $dep for $name: %s",
                                                \%install_request);
                            my $install_result = $self->dcapi()->install([\%install_request]);
                            if ($install_result->success())
                            {
                                $installed = $install_result;
                            }
                            else
                            {
                                return $install_result->add_error('dependency install',
                                                                  "Could not install dependency $dep for $name");
                            }
                        }
                    }
                    else
                    {
                        return $$search->add_error('dependency install',
                                                   "Could not install dependency $dep for $name");
                    }
                }
                else
                {
                    $self->dcapi()->log4("Sketch $name is missing dependency $dep");
                }
            }
            else
            {
                # put the first dependency found in the return
                $result->add_data_key('dependency', [$dep], $list->[0]);
            }
        }
    }

    return $result;
}

1;
