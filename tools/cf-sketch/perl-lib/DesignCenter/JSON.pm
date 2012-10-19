#
# DesignCenter::JSON
#
# DC-specific JSON stuff
#
# CFEngine AS, October 2012.
# Time-stamp: <2012-10-09 23:30:56 a10022>

package DesignCenter::JSON;

use File::Basename;
use Term::ANSIColor qw(:constants);

our $coder;
our $canonical_coder;

use JSON;
our $coder = JSON->new()->relaxed()->utf8()->allow_nonref();
# for storing JSON data so it's directly comparable
our $canonical_coder = JSON->new()->canonical()->utf8()->allow_nonref();

sub coder
{
  return $coder;
}

sub canonical_coder
{
  return $canonical_coder;
}

sub load
{
    # TODO: improve this
    my $f = shift @_;
    my $local_quiet = shift @_;

    my @j;

    if (Util::is_resource_local($f))
    {
        my $j;
        unless (open($j, '<', $f) && $j)
        {
            Util::color_warn "Could not inspect $f: $!" unless ($quiet || $local_quiet);
            return;
        }

        @j = <$j>;
    }
    else
    {
        my $j = Util::get_remote($f)
            or Util::color_die "Unable to retrieve $f";

        @j = split "\n", $j;
    }

    if (scalar @j)
    {
        chomp @j;
        s/\n//g foreach @j;
        s/^\s*(#|\/\/).*//g foreach @j;
        my $ret = $coder->decode(join '', @j);

        if (ref $ret eq 'HASH' &&
            exists $ret->{include} && ref $ret->{include} eq 'ARRAY')
        {
            foreach my $include (@{$ret->{include}})
            {
                if (dirname($include) eq '.' && ! -f $include)
                {
                    if (Util::is_resource_local($f)) {
                        $include = File::Spec->catfile(dirname($f), $include);
                    }
                    else {
                        $include = dirname($f)."/$include";
                    }
                }

                print "Including $include\n" unless $quiet;
                my $parent = load_json($include);
                if (ref $parent eq 'HASH')
                {
                    $ret->{$_} = $parent->{$_} foreach keys %$parent;
                }
                else
                {
                    Util::color_warn "Malformed include contents from $include: not a hash" unless $quiet;
                }
            }
            delete $ret->{include};
        }

        return $ret;
    }

    return;
}

sub is_json_boolean
{
    return ((ref shift) =~ m/JSON.*Boolean/);
}

sub recurse_print
{
    my $ref             = shift @_;
    my $prefix          = shift @_;
    my $unquote_scalars = shift @_;
    my $simplify_arrays = shift @_;

    my @print;

    # recurse for hashes
    if (ref $ref eq 'HASH')
    {
        if (exists $ref->{function} && exists $ref->{args})
        {
            push @print, {
                path => $prefix,
                type => 'string',
                value => sprintf('%s(%s)',
                                 $ref->{function},
                                 join(', ', map { my @p = recurse_print($_); $p[0]->{value} } @{$ref->{args}}))
            };
        }
        else
        {
            # warn Dumper [ $ref            ,
            #              $prefix         ,
            #              $unquote_scalars,
            #              $simplify_arrays];
            push @print, recurse_print($ref->{$_},
                                       sprintf("%s%s",
                                               ($prefix||''),
                                               $simplify_arrays ? "_${_}" : "[$_]"),
                                       $unquote_scalars,
                                       0)
                foreach sort keys %$ref;
        }
    }
    elsif (ref $ref eq 'ARRAY')
    {
        my $joined;

        if (scalar @$ref)
        {
            $joined = sprintf('{ %s }',
                              join(", ",
                                   map { s,\\,\\\\,g; s,",\\",g; "\"$_\"" } @$ref));
        }
        else
        {
            $joined = '{ "cf_null" }';
        }

        push @print, {
            path => $prefix,
            type => 'slist',
            value => $joined
        };
    }
    else
    {
        # convert to a 1/0 boolean
        $ref = ! ! $ref if is_json_boolean($ref);
        push @print, {
            path => $prefix,
            type => 'string',
            value => $unquote_scalars ? $ref : "\"$ref\""
        };
    }

    return @print;
}

sub pretty_print {
  my $json = shift;
  my $indent = shift || "";
  my $exclude = shift || undef;
  my @print = recurse_print($json, undef, 1, 1);
  my $result = "";
  foreach my $p (@print) {
    my $name = $p->{path};
    $name =~ s/^_(.*)$/$1/;
    next if $exclude && $name =~ /$exclude/;
    $result .= $indent.BLUE.$name.": ".RESET.$p->{value}."\n";
  }
  return $result;
}

1;
