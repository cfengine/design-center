package DCAPI::Sketch;

use strict;
use warnings;

use DCAPI::Terms;

use Util;
use Mo qw/default build builder is required option/;

use constant MEMBERS => qw/entry_point interface manifest metadata api namespace language/;
use constant META_MEMBERS => qw/name version description bundle_descriptions license tags depends authors/;

has dcapi        => ( is => 'ro', required => 1 );
has repo         => ( is => 'ro', required => 1 );
has desc         => ( is => 'ro', required => 1 );
has describe     => ( is => 'rw' );
has location     => ( is => 'ro', required => 1 );
has rel_location => ( is => 'ro', required => 1 );
has verify_files => ( is => 'ro');

# sketch-specific properties
has language    => ( is => 'rw' );
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
            elsif ($m eq 'language')
            {
                # it's OK to have a null language, it becomes "cfengine"
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

    $self->language('cfengine') unless $self->language();
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

    $ret{location} = $self->location();

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
    $ret{manifest_test} = [ grep { $self->manifest()->{$_}->{test} } @manifest ];
    $ret{manifest_exe} = [ grep {
        exists $self->manifest()->{$_}->{perm} &&
        (oct($self->manifest()->{$_}->{perm}) & 0111)
    } @manifest ];

    my %known = map { $_ => 1 } (@{$ret{manifest_cf}}, @{$ret{manifest_exe}}, @{$ret{manifest_docs}}, @{$ret{manifest_test}});
    $ret{manifest_extra} = [ grep { !exists $known{$_} } @manifest ];

    return \%ret;
}

sub test
{
    my $self = shift;
    my $options = shift || {};

    my $tests;
    eval
    {
        my @todo = @{$self->runfile_data_dump()->{manifest_test}};

        if ($options->{coverage})
        {
            $tests = scalar @todo;
            return;
        }

        @todo = map { sprintf("%s/%s", $self->location(), $_) } @todo;

        $ENV{HARNESS_VERBOSE} = ! ! $options->{test};
        $ENV{CFAGENT} = $self->dcapi()->cfagent();
        $ENV{CFPROMISES} = $self->dcapi()->cfpromises();

        require Test::Harness;

        chdir $self->location();
        my $output = '';
        open(my $log_fh, ">", \$output);

        my $total = {};
        my $failed = {};

        if (defined &Test::Harness::execute_tests)
        {
            ($total, $failed) = Test::Harness::execute_tests(
                                                             out => $log_fh,
                                                             tests => \@todo,
                                                            );

            foreach my $ref ($total, $failed)
            {
                next unless ref $ref eq 'HASH' && exists $ref->{bench};
                $ref->{bench} = $ref->{bench}->timestr();
            }
        }
        else
        {
            $total = { };
            $failed->{$_} = 1 foreach @todo;
            eval
            {
                Test::Harness::runtests(@todo);
                $total = $failed;
                $failed = {};
            };
            $output = $@;
        }

        $tests = {
                  total => $total,
                  failed => $failed,
                  log => $output,
                 };

        $tests->{success} = ! (ref $failed eq 'HASH' && scalar keys %{$failed});

        # print Util::dump_ref($tests);
    };

    return defined $tests ? $tests : { total => undef, ok => undef, failed => undef, log => [$@] };
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
Language: {{language}}

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

    my $inc = 'README.include';
    my $incfile = sprintf '%s/%s', $self->location(), $inc;

    if (-e $incfile)
    {
        open my $i, '<', $incfile or warn "Could not include defined include file $incfile";
        while (<$i>)
        {
         $data{description} .= $_;
        }
    }

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
        # TODO: use api_describe
        my $spec = $data{api}->{$bundle};

        my $bundle_desc = '';
        my $bundle_descriptions = $data{bundle_descriptions};
        $bundle_descriptions = {} if ref $bundle_descriptions ne 'HASH';

        $bundle_desc = sprintf(' (description: %s)', $bundle_descriptions->{$bundle})
         if exists $bundle_descriptions->{$bundle};

        push @p, "### bundle: $bundle$bundle_desc";
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

sub api_describe
{
    my $self = shift;
    my $bundle = shift;

    my $bundle_api = Util::hashref_search($self->api(), $bundle);
    return {} unless $bundle_api;

    my %ret;
    foreach my $param (@$bundle_api)
    {
        my $return = DCAPI::Activation::return_type($param->{type});
        $ret{$param->{name}} = {
                                type => $param->{type},
                               };
    }

    return \%ret;
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

    $self->dcapi()->log5("getting inputs of sketch %s, relocate %s, recurse %s",
                        $self->name(),
                        $relocate,
                        $recurse);

    my @inputs;
    if ($recurse)
    {
        my $depcheck = $self->resolve_dependencies(install => 0);
        if ($depcheck->success())
        {
            foreach my $dep (keys %{$depcheck->data()})
            {
                $self->dcapi()->log4("Sketch %s looking for dependency %s",
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

# these dependencies should be checked at runtime
sub runtime_dependencies
{
    my $self = shift @_;
    my @deps;
    foreach (qw/os classes/)
    {
        next unless exists $self->depends()->{$_};
        push @deps, $self->depends()->{$_};
    }

    return \@deps;
}

sub runtime_context
{
    my $self = shift @_;

    my $runtime_deps = $self->runtime_dependencies();
    return Util::recurse_context($runtime_deps) || 'any';
}


# these dependencies should be checked at install time
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
        if ($dep eq 'os' || $dep eq 'classes')
        {
            $self->dcapi()->log2("At install time, ignoring sketch $name dependency %s: %s",
                                 $dep,
                                 $deps{$dep});
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
        elsif ($dep eq 'perl')
        {
            if (exists $deps{$dep}->{version})
            {
                my $v = $deps{$dep}->{version};
                eval
                {
                    die if $^V lt $v;
                };

                if ($@)
                {
                    $self->dcapi()->log2("Perl version requirement of sketch $name not OK: requested %s > actual $^V", $v);
                    return $result->add_error('dependency',
                                              "Perl version $^V below required $v for sketch $name");
                }
                else
                {
                    $self->dcapi()->log3("Perl version requirement of sketch $name OK: %s", $v);
                }
            }

            if (exists $deps{$dep}->{modules})
            {
                my $m = $deps{$dep}->{modules};
                if (ref $m ne 'ARRAY')
                {
                    $self->dcapi()->log2("Perl modules requirement of sketch $name was not an ARRAY: %s", $m);
                    return $result->add_error('dependency',
                                              "Perl modules requirement $m in wrong format for sketch $name");
                }

                foreach my $module (@$m)
                {
                    $module =~ s/[^\w:]//g;
                    eval "require $module";

                    if ($@)
                    {
                        $self->dcapi()->log2("Perl module requirement of sketch $name not OK: %s ($!)", $module);
                        return $result->add_error('dependency',
                                                  "Perl module $module missing for sketch $name");
                    }
                    else
                    {
                        $self->dcapi()->log3("Perl module requirement of sketch $name OK: %s", $module);
                    }
                }
            }
        }
        elsif (ref $deps{$dep} eq 'HASH') # a HASH is a sketch dependency.
        {
            my %install_request = ( sketch => $dep, target => $options{target}, force => $options{force} );
            my @criteria = (["name", "equals", $dep]);
            if (exists $deps{$dep}->{version})
            {
                push @criteria, ["version", ">=", $deps{$dep}->{version}];
            }

            my $list = $self->dcapi()->collect_int($self->dcapi()->repos(),
                                                   \@criteria,
                                                   { flatten => 1 });

            if (scalar @$list < 1 || $options{force})
            {
                if ($options{install})
                {
                    # try to install the dependency
                    my $search = $self->dcapi()->search(\@criteria);
                    my $installed = 0;
                    my $install_result;
                    if ($search->success())
                    {
                        my $sdata = Util::hashref_search($search->data(), 'search') || {};

                        foreach my $srepo (sort keys %$sdata)
                        {
                            $install_request{source} = $srepo;
                            $self->dcapi()->log("Trying to install dependency $dep for $name: %s",
                                                \%install_request);
                            $install_result = $self->dcapi()->install([\%install_request]);
                            if ($install_result->success())
                            {
                                $installed = $install_result;
                                last;
                            }
                        }

                        unless ($installed)
                        {
                            return $install_result->add_error('dependency install',
                                                              "Could not install dependency $dep for $name");
                        }
                    }
                    else
                    {
                        return $search->add_error('dependency install',
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
        else
        {
            $self->dcapi()->log5("Ignoring sketch $name dependency $dep");
        }
    }

    return $result;
}

1;
