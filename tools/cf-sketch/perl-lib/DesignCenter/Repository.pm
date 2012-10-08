#!/usr/bin/env perl -w
#
# DesignCenter::Repository
# Representation of a repository containing sketches
#
# Diego Zamboni <diego.zamboni@cfengine.com>
# Time-stamp: <2012-10-08 16:54:37 a10022>

package DesignCenter::Repository;

use Carp;
use Util;
use File::Basename;
use File::Spec;
use File::Compare;
use File::Copy;
use Term::ANSIColor qw(:constants);

use DesignCenter::Config;
use DesignCenter::Sketch;

our $AUTOLOAD;                  # it's a package global

# Allowed data fields, for setters/getters
my %fields = (
    # Internal fields
    _basedir => undef,
    _local => undef,
    _lines => undef,
    # Default repository - base location where the cfsketches file can be found
    uri => undef,
    );

######################################################################

# Automatically generate setters/getters, i.e. MAGIC
sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;             # strip fully-qualified portion

    unless (exists $self->{_permitted}->{$name} ) {
        croak "Can't access `$name' field in class $type";
    }

    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}

sub new {
    my $class = shift;
    my $uri = shift;
    # Data initialization
    my $self  = {
        _permitted => \%fields,
        %fields,
    };
    # Get the URI from the argument if provided (else see default value above)
    $self->{uri} = $uri || DesignCenter::Config->installsource || $self->{uri};
    die "Need the repository URI for creation" unless $self->{uri};

    # Convert myself into an object
    bless($self, $class);

    # Compute some other basic characteristics
    $self->_setup;

    return $self;
}

sub _setup {
    my $self=shift;
    $self->_basedir(dirname($self->uri));
    $self->_local(Util::is_resource_local($self->_basedir));
}

sub list {
    my $self = shift;
    my @terms = @_;
    my $source = DesignCenter::Config->installsource;
    my $base_dir = $self->_basedir;
    my $search = $self->search_internal([]);
    my $local_dir = $self->_local;
    my @result = ();

  SKETCH:
    foreach my $sketch (sort keys %{$search->{known}}) {
        my $dir = $local_dir ? File::Spec->catdir($base_dir, $search->{known}->{$sketch}) : "$base_dir/$search->{known}->{$sketch}";
        foreach my $term (@terms) {
            if ($sketch =~ m/$term/i || $dir =~ m/$term/i) {
                push @result, DesignCenter::Sketch->new(name => $sketch,
                                                        location => $dir,
                    );
                next SKETCH;
            }
        }
    }
    return @result;
}

sub search_internal {
    my $self = shift;
    my $source = $self->uri;
    my $sketches = shift @_;

    my %known;
    my %todo;
    my $local_dir = $self->_local;

    if ($local_dir) {
        Util::color_die "cf-sketch inventory source $source must be a file"
            unless -f $source;

        open(my $invf, '<', $source)
            or Util::color_die "Could not open cf-sketch inventory file $source: $!";

        while (<$invf>) {
            my $line = $_;

            my ($dir, $sketch, $etc) = (split ' ', $line, 3);
            $known{$sketch} = $dir;
        }
    } else {
        my @lines = @{$self->_lines};
        unless (@lines) {
            my $invd = Util::get_remote($source)
                or Util::color_die "Unable to retrieve $source : $!\n";

            @lines = split "\n", $invd;
            $self->_lines(\@lines);
        }
        foreach my $line (@lines) {
            my ($dir, $sketch, $etc) = (split ' ', $line, 3);
            $known{$sketch} = $dir;
        }
    }

    foreach my $s (@$sketches) {
      if (exists($known{$s}) || grep { $_ eq $s } values(%known)) {
        $todo{$s} = $known{$s};
      }
      else {
        Util::error "I could not find sketch '$s' in the source repository.\n";
      }
    }

    return { known => \%known, todo => \%todo };
}

sub install
{
    my $self = shift;
    my $sketches = shift;

    my $dest_repo = DesignCenter::Config->installtarget;
    push @{DesignCenter::Config->repolist}, $dest_repo unless grep { $_ eq $dest_repo } @{DesignCenter::Config->repolist};

    Util::color_die "Can't install: no install target supplied!"
        unless defined $dest_repo;

    my $source = $self->uri;
    my $base_dir = $self->_basedir;
    my $local_dir = $self->_local;

    print "Loading cf-sketch inventory from $source\n" if DesignCenter::Config->verbose;

    my $search = $self->search_internal($sketches);

    my %known = %{$search->{known}};
    my %todo = %{$search->{todo}};

    unless (scalar keys %todo) {
      Util::error "Nothing to install.";
    }

    foreach my $sketch (sort keys %todo)
    {
        print BLUE "Installing $sketch\n" unless $quiet;
        my $dir = $local_dir ? File::Spec->catdir($base_dir, $todo{$sketch}) : "$base_dir/$todo{$sketch}";
        my $skobj = DesignCenter::Sketch->new(name => $sketch,
                                              location => $local_dir ? File::Spec->rel2abs($dir) : $dir);
        $skobj->load;
        my $data = $skobj->json_data;

        Util::color_die "Sorry, but sketch $sketch could not be loaded from $dir!"
            unless $data;

        my %missing = map { $_ => 1 } $self->missing_dependencies($data->{metadata}->{depends});

        # note that this will NOT catch circular dependencies!
        foreach my $missing (keys %missing)
        {
            print "Trying to find $missing dependency\n" unless $quiet;

            if (exists $todo{$missing})
            {
                print "$missing dependency is to be installed or was installed already\n"
                    unless $quiet;
                delete $missing{$missing};
            }
            elsif (exists $known{$missing})
            {
                print "Found $missing dependency, trying to install it\n" unless $quiet;
                $self->install([$missing]);
                delete $missing{$missing};
                $todo{$missing} = $known{$missing};
            }
        }

        my @missing = sort keys %missing;
        if (scalar @missing)
        {
            if (DesignCenter::Config->force)
            {
                Util::color_warn "Installing $sketch despite unsatisfied dependencies @missing"
                    unless $quiet;
            }
            else
            {
                Util::color_die "Can't install: $sketch has unsatisfied dependencies @missing";
            }
        }

        printf("Installing %s (%s) into %s\n",
               $sketch,
               $data->{file},
               $dest_repo)
            if DesignCenter::Config->verbose;

        my $install_dir = File::Spec->catdir($dest_repo,
                                             split('::', $sketch));

        my $module_install_dir = File::Spec->catfile($dest_repo, DesignCenter::Config->modulepath);

        if (CFSketch::maybe_ensure_dir($install_dir))
        {
            print "Created destination directory $install_dir\n" if DesignCenter::Config->verbose;
            print "Checking and installing sketch files.\n" unless $quiet;
            my $anything_changed = 0;
            foreach my $file ($CFSketch::SKETCH_DEF_FILE, sort keys %{$data->{manifest}})
            {
                my $file_spec = $data->{manifest}->{$file};
                # build a locally valid install path, while the manifest can use / separator
                my $source = Util::is_resource_local($data->{dir}) ? File::Spec->catfile($data->{dir}, split('/', $file)) : "$data->{dir}/$file";

                my $dest;

                if ($file_spec->{module})
                {
                    if (CFSketch::maybe_ensure_dir($module_install_dir))
                    {
                        print "Created module destination directory $module_install_dir\n" if DesignCenter::Config->verbose;
                        $dest = File::Spec->catfile($module_install_dir, split('/', $file));
                    }
                    else
                    {
                        Util::color_warn "Could not make install directory $module_install_dir, skipping $sketch";
                        next;
                    }
                }
                else
                {
                    $dest = File::Spec->catfile($install_dir, split('/', $file));
                }

                my $dest_dir = dirname($dest);
                Util::color_die "Could not make destination directory $dest_dir"
                    unless CFSketch::maybe_ensure_dir($dest_dir);

                my $changed = 1;

                # TODO: maybe disable this?  It can be expensive for large files.
                if (!DesignCenter::Config->force &&
                    Util::is_resource_local($data->{dir}) &&
                    compare($source, $dest) == 0)
                {
                    Util::color_warn "  Manifest member $file is already installed in $dest"
                        if DesignCenter::Config->verbose;
                    $changed = 0;
                }

                if ($changed)
                {
                    if ($dryrun)
                    {
                        print YELLOW "  DRYRUN: skipping installation of $source to $dest\n";
                    }
                    else
                    {
                        if (Util::is_resource_local($data->{dir}))
                        {
                            copy($source, $dest) or Util::color_die "Aborting: copy $source -> $dest failed: $!";
                        }
                        else
                        {
                            my $rc = getstore($source, $dest);
                            Util::color_die "Aborting: remote copy $source -> $dest failed: error code $rc"
                                unless is_success($rc)
                        }
                    }
                }

                if (exists $file_spec->{perm})
                {
                    if ($dryrun)
                    {
                        print YELLOW "  DRYRUN: skipping chmod $file_spec->{perm} $dest\n";
                    }
                    else
                    {
                        chmod oct($file_spec->{perm}), $dest;
                    }
                }

                if (exists $file_spec->{user})
                {
                    # TODO: ensure this works on platforms without getpwnam
                    # TODO: maybe add group support too
                    my ($login,$pass,$uid,$gid) = getpwnam($file_spec->{user})
                        or Util::color_die "$file_spec->{user} not in passwd file";

                    if ($dryrun)
                    {
                        print YELLOW "  DRYRUN: skipping chown $uid:$gid $dest\n";
                    }
                    else
                    {
                        chown $uid, $gid, $dest;
                    }
                }

                print "  $source -> $dest\n" if $changed && DesignCenter::Config->verbose;
                $anything_changed += $changed;
            }

            unless ($quiet) {
                if ($anything_changed) {
                    print GREEN "Done installing $sketch\n";
                }
                else {
                    print GREEN "Everything was up to date - nothing changed.\n";
                }
            }
        }
        else
        {
            Util::color_warn "Could not make install directory $install_dir, skipping $sketch";
        }
    }
}

sub missing_dependencies
{
    my $self = shift;
    my $deps = shift;
    my @missing;

    my %tocheck = %$deps;

    foreach my $repo (@{DesignCenter::Config->repolist})
    {
        my $contents = CFSketch::repo_get_contents($repo);
        foreach my $dep (sort keys %tocheck)
        {
            if ($dep eq 'os' &&
                ref $tocheck{$dep} eq 'ARRAY')
            {
                # TODO: get uname from cfengine?
                # pick either /bin/uname or /usr/bin/uname
                my $uname_path = -x '/bin/uname' ? '/bin/uname -o' : '/usr/bin/uname -s';
                my $uname = 'unknown';
                if (-x (split ' ', $uname_path)[0])
                {
                    $uname = `$uname_path`;
                    chomp $uname;
                }

                foreach my $os (sort @{$tocheck{$dep}})
                {
                    if ($uname =~ m/$os/i)
                    {
                        print "Satisfied OS dependency: $uname matched $os\n"
                            if DesignCenter::Config->verbose;

                        delete $tocheck{$dep};
                    }
                }

                if (exists $tocheck{$dep})
                {
                    print YELLOW "Unsatisfied OS dependencies: $uname did not match [@{$deps->{$dep}}]\n"
                        if DesignCenter::Config->verbose;
                }
            }
            elsif ($dep eq 'cfengine' &&
                   ref $tocheck{$dep} eq 'HASH' &&
                   exists $tocheck{$dep}->{version})
            {
                my $version = CFSketch::cfengine_version();
                if ($version ge $tocheck{$dep}->{version})
                {
                    print "Satisfied cfengine version dependency: $version present, needed ",
                    $tocheck{$dep}->{version}, "\n"
                        if DesignCenter::Config->veryverbose;

                    delete $tocheck{$dep};
                }
                else
                {
                    print YELLOW "Unsatisfied cfengine version dependency: $version present, need ",
                    $tocheck{$dep}->{version}, "\n"
                        if DesignCenter::Config->verbose;
                }
            }
            elsif (exists $contents->{$dep})
            {
                my $dd = $contents->{$dep};
                # either the version is not specified or it has to match
                if (!exists $tocheck{$dep}->{version} ||
                    $dd->{metadata}->{version} >= $tocheck{$dep}->{version})
                {
                    print "Found dependency $dep in $repo\n" if DesignCenter::Config->veryverbose;
                    # TODO: test recursive dependencies, right now this will loop
                    # TODO: maybe use a CPAN graph module
                    push @missing, $self->missing_dependencies($dd->{metadata}->{depends});
                    delete $tocheck{$dep};
                }
                else
                {
                    print YELLOW "Found dependency $dep in $repo but the version doesn't match\n"
                        if DesignCenter::Config->verbose;
                }
            }
        }
    }

    push @missing, sort keys %tocheck;
    if (scalar @missing)
    {
        print YELLOW "Unsatisfied dependencies: @missing\n" unless $quiet;
    }

    return @missing;
}
