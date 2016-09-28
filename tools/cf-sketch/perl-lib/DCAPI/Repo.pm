package DCAPI::Repo;

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Mo qw/default build builder is required option/;

use Util;
use DCAPI::Sketch;

use constant SKETCHES_FILE => 'cfsketches.json';
use constant SKETCH_JSON_FILE => 'sketch.json';

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

sub make_inv_file
{
    my $api = shift @_;
    my $repodir = shift @_;

    return undef unless Util::is_resource_local($repodir);

    my $result = DCAPI::Result->new(api => $api,
                                    status => 1,
                                    success => 1,
                                    data => { });

    $api->log3("Regenerating index: searching for sketches in %s",
               $repodir);

    my @todo;
    my $old_dir = $repodir;
    # fall back to $old_dir if glob() fails (seen on Darwin for instance)
    $repodir = glob($repodir) || $old_dir;

    require File::Find;
    File::Find::find(sub
                     {
                         return unless $_ eq SKETCH_JSON_FILE;
                         push @todo, $File::Find::name;
                     }, $repodir);

    $repodir = dirname($repodir) if $repodir =~ m/cfsketches.json$/;
    my $index_file = sprintf("%s/%s", $repodir, SKETCHES_FILE);

    if (open my $index, '>', $index_file)
    {
        my $encoder = JSON::PP->new()->utf8()->canonical();
        foreach my $f (sort @todo)
        {
            $api->log5("Regenerating index: examining %s", $f);
            eval
            {
                my $d = dirname($f);
                $d =~ s,^$repodir/,,;
                $d =~ s,^\./,,;
                $api->log5("Regenerating index: on sketch dir $d");
                open my $fh, '<', $f or warn "Couldn't open $f: $!";
                my $out = $api->decode(join('', <$fh>));
                $out->{api} = {} unless exists $out->{api};

                # note we encode BEFORE writing a line
                my $out_string = sprintf("%s\t%s\n", $d, $encoder->pretty(0)->encode($out));
                # TODO: add proper regenerate_index filtering
                return unless $out_string =~ m/enterprise_compatible/;
                print $index $out_string;
            };

            if ($@)
            {
                $result->add_error($f, $@);
            }
        }
    }
    else
    {
        $api->log("Regenerating index: could not save $index_file");
        $result->add_error($index_file, $!);
    }

    return $result;
}

sub save_inv_file
{
    my $self = shift;

    my $result = make_inv_file($self->api(), $self->location());
    return ! ! $result->success();
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

    # copy the sketch files as in the manifest.
    my $abs_location = sprintf("%s/%s", $self->location(), $sketch->rel_location);

    my $manifest = $sketch->manifest();

    my @files = sort keys %$manifest;
    push @files, SKETCH_JSON_FILE unless exists $manifest->{SKETCH_JSON_FILE()};
    foreach my $file (@files)
    {
        my $perms = Util::hashref_search($manifest->{$file}, qw/perm/);
        my $source = $sketch->location() . "/$file";
        my $dest = "$abs_location/$file";

        require File::Copy;
        $self->api()->log4("Installing sketch %s: copying %s to %s",
                           $sketch->name(),
                           $source,
                           $dest);

        my $dest_dir = dirname($dest);
        Util::dc_make_path($dest_dir);

        unless (-d $dest_dir)
        {
            $result->add_error('installation', "could not create $abs_location");
        }

        if (-d $dest_dir && ! -w $dest_dir)
        {
            $result->add_error('installation', "created $abs_location but it's not writeable.  fix your umask.");
        }

        if (Util::is_resource_local($source))
        {
            File::Copy::copy($source, $dest);
        }
        else
        {
            my $data = Util::get_remote($source);
            if (defined $data)
            {
                open my $out, '>', $dest;
                print $out $data;
                close $out;
            }
        }

        if (-f $dest)
        {
            $result->add_data_key('installation', ["install", $sketch->name(), $file], $dest);

            open my $destfh, '<', $dest;
            my @lines;
            if ($destfh)
            {
                @lines = <$destfh>;
                close $destfh;
            }
            else
            {
                $result->add_error('installation', "could not read '%s' after install: $!", $dest);
            }

            my @newlines;
            foreach my $line (@lines)
            {
                if ($line =~ m/^\s*#\@include\s+"([^"]+)"\s*$/)
                {
                    my $incname = sprintf("%s/%s", dirname($dest), $1);
                    my $repo = $self->location();
                    $incname =~ s/.*REPO/$repo/g;
                    my $include;
                    if (open $include, '<', $incname)
                    {
                        push @newlines, <$include>;
                        $result->add_data_key('installation', ["include", $sketch->name(), $dest, $incname], $dest);
                        close $include;
                    }
                    else
                    {
                        $result->add_error('installation', "could not include '$incname' requested by '$dest' after install: $!");
                    }
                }
                else
                {
                    push @newlines, $line;
                }
            }

            # only write if the content is different
            if (join('', @newlines) ne join('', @lines))
            {
                open my $rewrite, '>', $dest;
                if ($rewrite)
                {
                    print $rewrite @newlines;
                    close $rewrite;
                }
                else
                {
                    $result->add_error('installation', "could not rewrite '$dest' after install+include: $!");
                }
            }

            $result->add_data_key('installation', ["install", $sketch->name(), $file], $dest);

            if (defined $perms)
            {
                my $p = oct($perms);
                if ($p > 0)
                {
                    $self->api()->log4("Installing sketch %s: setting %s permissions to %s",
                                       $sketch->name(),
                                       $dest,
                                       $perms);
                    chmod($p, $dest);
                    my $mode = (stat($dest))[2];
                    if ($p != ($mode & 07777))
                    {
                        $self->api()->log("Installing sketch %s: could not set %s permissions to %s",
                                          $sketch->name(),
                                          $dest,
                                          $perms);
                        $result->add_warning('installation',
                                             sprintf("$file was installed in $abs_location but the permissions could not be set to '$perms' (now they are %o)",
                                                     $mode & 07777));
                    }
                }
                else
                {
                    $self->api()->log("Installing sketch %s: could not set %s permissions, given octal string '%s' was invalid",
                                      $sketch->name(),
                                      $dest,
                                      $perms);
                    $result->add_error('installation', "$file was installed in $abs_location but the permissions could not be set from the invalid octal string '$perms'");
                }
            }
        }
        else
        {
        $self->api()->log("Installing sketch %s: failed to copy %s to %s",
                          $sketch->name(),
                          $source,
                          $dest);
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
     if 0 == $inv_save;

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

    # delete the sketch files as in the manifest
    my $abs_location = sprintf("%s/%s", $self->location(), $sketch->rel_location);

    my $manifest = $sketch->manifest();

    $self->api()->log4("Uninstalling sketch %s: removing directory tree %s",
                       $sketch->name(),
                       $abs_location);

    Util::dc_remove_tree($abs_location);

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
     if 0 == $inv_save;

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
