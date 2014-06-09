use warnings;
use strict;
use JSON;

package dc;

use constant CODER => JSON->new()->relaxed()->utf8()->allow_nonref();

sub init
{
    my ($bundle, $vardata, $key, $subkey) = @ARGV;
    die "Not enough arguments" unless defined $subkey;

    my $data;
    {
        local $/;
        open my $fh, '<', $vardata or die "Couldn't open $vardata: $!";
        $data = CODER->decode(join("", <$fh>));
    }

    my $params = $data->{$key}->{$subkey};
    die "Could not find ARRAY parameters for '$bundle' from file '$vardata', key '$key', subkey '$subkey'"
     unless ref $params eq 'ARRAY';

    my $location;
    foreach (@$params)
    {
        # look for the run environments and replace them with the expanded version
        next unless defined ref $_;
        next unless ref $_ eq '';
        next unless exists $data->{$key}->{$_};
        $_ = $data->{$key}->{$_};
    }

    foreach (@$params)
    {
        # look for the metadata
        next unless defined ref $_;
        next unless ref $_ eq 'HASH';
        next unless defined $_->{api};
        next unless defined $_->{location};
        $location = $_->{location};
    }

    if (defined $location)
    {
        foreach (@$params)
        {
            next unless defined ref $_;
            next unless ref $_ eq '';
            s/\$\(this\.promise_dirname\)/$location/g;
        }
    }

    no strict 'refs';
    return "main::$bundle"->(@{$params});
}

sub module
{
    my ($metadata, $args, $classes, $classtags) = @_;

    #print CODER->encode($metadata), "\n";
    my $api = $metadata->{api};
    my $id = $metadata->{activation}->{identifier};
    die "Undefined activation ID" unless ref $id eq '';
    die "Undefined API for activation '$id'" unless ref $api eq 'HASH';

    if (defined $classtags)
    {
        print "^meta=", join(",", @$classtags), "\n";
    }

    $classes = [] unless defined $classes;
    foreach my $class (@$classes)
    {
        $class =~ s/\W/_/g;
        print "+$class\n";
    }

    # requires Redmine#6063 to work
    # print "^context=return_$id\n";

    print "^context=dcreturn\n";
    foreach my $return_parameter (grep { $api->{$_}->{type} eq 'return' } keys %$api)
    {
        die "Given arguments don't contain return parameter '$return_parameter'"
         unless exists $args->{$return_parameter};

        # requires Redmine#6063 to work
        # printf "%%%s=%s\n", $return_parameter, CODER->encode($args->{$return_parameter});
        printf "%%%s_%s=%s\n", $id, $return_parameter, CODER->encode($args->{$return_parameter});
    }

    return 1;
}

1;
