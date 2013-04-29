package DCAPI::Terms;

use strict;
use warnings;

use Util;

use Mo qw/default build builder is required option/;

has api   => ( is => 'ro', required => 1 );
has terms => ( is => 'rw' );

sub BUILD
{
    my $self = shift;
    my $terms = $self->terms();

    # it's either boolean or a HASH ref
    $self->api()->log5('Building terms with data %s', $terms);
}

sub matches
{
    my $self = shift;
    my $data = shift;
    my $terms = $self->terms();

    $self->api()->log5('Matching terms %s against %s', $terms, $data);

    my $ok = [];

    if (ref $terms eq '')               # string at top
    {
        $terms = [ [ 'name', 'matches', $terms ] ];
    }

    if (ref $terms eq 'ARRAY')
    {
        foreach my $q (@$terms)
        {
            if (Util::is_json_boolean($q))
            {
                $q = $q ? '.*' : 'nothing should match this';
            }

            if (ref $q eq '')
            {
                $q = [ 'name', 'matches', $q ];
            }

            next unless ref $q eq 'ARRAY';

            eval
            {
                my ($k, $check, $v) = @$q;
                $k = [$k] unless ref $k eq 'ARRAY';

                if ($check eq 'matches' || $check eq 'equals')
                {
                    my $data_locate = Util::hashref_search($data, @$k);
                    if (ref $data_locate ne 'ARRAY')
                    {
                        $data_locate = [ $data_locate ];
                    }

                    $self->api()->log5('Term %s checking against %s', $q, $data_locate);

                    my $this_ok = [];
                    foreach my $datum (@$data_locate)
                    {
                        if ((!defined $datum && !defined $v) ||
                            ($check eq 'matches' && defined $datum && defined $v && $datum =~ m/$v/i) ||
                            ($check eq 'equals' && defined $datum && defined $v && $datum eq $v)) {
                            push @$this_ok, [$k, $v] if $ok;
                        }
                        else
                        {
                        }
                    }

                    if (scalar @$this_ok)
                    {
                        push @$ok, @$this_ok;
                    }
                    else
                    {
                        undef $ok;
                    }
                }
                elsif ($check =~ m/[<>]=?/) # < > <= >=
                {
                    my $datum = Util::hashref_search($data, @$k);
                    $self->api()->log5('Term %s comparing against %s', $q, $datum);
                    if (defined $datum && defined $v)
                    {
                        if (($check eq '>' && $datum gt $v) ||
                            ($check eq '>=' && $datum ge $v) ||
                            ($check eq '<' && $datum lt $v) ||
                            ($check eq '<=' && $datum le $v)) {
                            push @$ok, [$k, $v] if $ok;
                        }
                        else
                        {
                            undef $ok;
                        }
                    }
                }
                else
                {
                    $self->api()->log('Invalid term check %s, failing', $check);
                }
            };
        }

        return $ok if $ok;
    }
    else
    {
        $self->api()->log5('Terms %s always match', $terms);
        return $terms;
    }

    return;                     # no match
}

sub equals
{
    my $self = shift;
    my $other = shift @_;

    return (ref $self eq ref $other &&
            $self->api()->encode($self->terms()) eq $self->api()->encode($other->terms()));
}

1;
