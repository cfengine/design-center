package DCAPI::Repo;

use strict;
use warnings;

use File::Spec;
use Mo qw/default build builder is required option/;

use Util;
use DCAPI::Sketch;

use constant SKETCHES_FILE => 'cfsketches.json';

has api       => ( is => 'ro', required => 1 );
has location  => ( is => 'ro', required => 1 );
has local     => ( is => 'rw' );
has writeable => ( is => 'rw', default => sub { 0 });
has inv_file  => ( is => 'rw');
has sketches  => ( is => 'ro', default => sub { [] } );

sub BUILD
{
    my $self = shift;
    $self->local(Util::is_resource_local($self->location()));
    $self->writeable($self->local() && -w $self->location());

    my $inv_file = sprintf("%s/%s", $self->location(), SKETCHES_FILE);

    my ($inv, $reason);

    if ($self->local() && (!-e $inv_file || 0 == -s $inv_file))
    {
        $inv = [];
    }
    else
    {
        ($inv, $reason) = $self->api()->load_raw($inv_file);
    }

    die "Can't use repository without a valid inventory file in $inv_file: $reason"
     unless defined $inv;

    foreach my $line (@$inv)
    {
        my ($location, $desc) = split ' ', $line, 2;

        my $abs_location = sprintf("%s/%s", $self->location(), $location);
        eval
        {
            push @{$self->sketches()},
            DCAPI::Sketch->new(location => $abs_location,
                               rel_location => $location,
                               desc => $desc,
                               dcapi => $self->api(),
                               repo => $self,
                               verify_files => $self->local());
        };

        if ($@)
        {
            $self->api->log($@);
        }

    }

    $self->inv_file($inv_file);
}

sub data_dump
{
    my $self = shift;
    return
    {
     location => $self->location(),
     writeable => $self->writeable(),
     inv_file => $self->inv_file(),
     sketches => [map { $_->data_dump() } @{$self->sketches()}],
    };
}

sub sketches_dump
{
    my $self = shift;
    my @lines =
    sort { $a cmp $b }
    map { sprintf("%s %s", $_->rel_location(), $_->desc()); }
    @{$self->sketches()};

    return @lines;
}

sub save_inv_file
{
    my $self = shift;

    open my $fh, '>', $self->inv_file()
    or $self->api()->log("Repo at %s could not save inventory file %s: $!",
                         $self->location(),
                         $self->inv_file());

    return unless $fh;

    print $fh "$_\n" foreach $self->sketches_dump();
    close $fh or return 0;

    return 1;
}

sub list
{
    my $self = shift;
    my $term_data = shift @_;

    return grep { $_->matches($term_data) } @{$self->sketches()};
}

sub find_sketch
{
    my $self = shift;
    my $name = shift || 'nonesuch';
    my $version = shift;

    foreach (@{$self->sketches()})
    {
        next if $name ne $_->name();
        next if (defined $version && $version ne $_->version());
        return $_;
    }

    return;
}

sub describe
{
    my $self = shift;
    my $sketches = shift;
    my $firstfound = shift;

    foreach my $sname (keys %$sketches)
    {
        my $s = $self->find_sketch($sname);
        next unless defined $s;
        return $s if $firstfound;
        push @{$sketches->{$s->name()}}, $s->describe();
    }

    return $sketches;
}

sub install
{
    my $self = shift @_;
    my $from = shift @_;
    my $sketch = shift @_;

    my $result = DCAPI::Result->new(api => $self->api(),
                                    status => 1,
                                    success => 1,
                                    data => { });

    # 1. copy the sketch files as in the manifest.  USE CFE
    my $abs_location = sprintf("%s/%s", $self->location(), $sketch->rel_location);

    my $manifest = $sketch->manifest();

    my @todo;
    foreach my $file (sort keys %$manifest)
    {
        my $perms = Util::hashref_search($manifest->{$file}, qw/perm/);
        $self->api()->log("Will copy sketch %s:%s from %s to %s",
                          $sketch->name(),
                          $file,
                          $sketch->location(),
                          $abs_location);
        push @todo, sprintf('"%s/%s" copy_from => no_backup_cp("%s/%s") %s ;',
                            $abs_location,
                            $file,
                            $sketch->location(),
                            $file,
                            defined $perms ? ", perms => m('$perms')" : '');
    }

    $self->api()->run_cf_promises({ files => join("\n", @todo) });

    foreach my $file (sort keys %$manifest)
    {
        my $full_file = "$abs_location/$file";
        if (-f $full_file)
        {
            $result->add_data_key('installation', [$sketch->name(), $file], $full_file);
        }
        else
        {
            $result->add_error('installation', "$file was not installed in $abs_location");
        }
    }

    eval
    {
        @{$self->sketches()} = grep { $_->name() ne $sketch->name() } @{$self->sketches()};

        push @{$self->sketches()},
         DCAPI::Sketch->new(location => $abs_location,
                            rel_location => $sketch->rel_location(),
                            desc => $sketch->desc(),
                            dcapi => $self->api(),
                            repo => $self,
                            verify_files => 1);
    };

    if ($@)
    {
        return $result->add_error('installation', $@);
    }

    my $inv_save = $self->save_inv_file();
    return $result->add_error('installation',
                              "Could not save the inventory file!")
     unless $inv_save;

    $result->add_data_key('installation', 'inventory_save', $inv_save);

    return $result;
}

sub uninstall
{
    my $self = shift @_;
    my $sketch = shift @_;

    my $result = DCAPI::Result->new(api => $self->api(),
                                    status => 1,
                                    success => 1,
                                    data => { });

    # 1. delete the sketch files as in the manifest.  USE CFE
    my $abs_location = sprintf("%s/%s", $self->location(), $sketch->rel_location);

    my $manifest = $sketch->manifest();

    # I know I can do this with File::Path's rmtree().  Shut up, conscience.
    my @todo = (
                sprintf('"%s" delete => tidy, file_select => all, depth_search => recurse_sketch;',
                        $abs_location),
               );

    $self->api()->run_cf_promises({ files => join("\n", @todo) });

    if (-d $abs_location)
    {
        return $result->add_error('uninstallation',
                                  "It seems that $abs_location could not be removed");
    }

    my @sketches = grep { $_ != $sketch } @{$self->sketches()};
    @{$self->sketches()} = @sketches;

    $self->api()->log("Saving the inventory after uninstalling %s from repo %s",
                      $sketch->name(),
                      $self->location());

    my $inv_save = $self->save_inv_file();

    return $result->add_error('uninstallation',
                              "Could not save the inventory file!")
     unless $inv_save;

    $result->add_data_key('uninstallation', 'inventory_save', $inv_save);

    return $result;
}

sub equals
{
    my $self = shift;
    my $other = shift @_;

    return (ref $self eq ref $other &&
            $self->location() eq $other->location());
}

1;
