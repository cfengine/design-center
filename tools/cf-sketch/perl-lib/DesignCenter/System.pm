#
# DesignCenter::System
#
# Local system, including its installed sketches
#
# CFEngine AS, October 2012

package DesignCenter::System;

use Carp;
use Term::ANSIColor qw(:constants);

use DesignCenter::Config;
use DesignCenter::Repository;
use DesignCenter::Sketch;

our $AUTOLOAD;                  # it's a package global

# Allowed data fields, for setters/getters
my %fields = (
              install_dest => nil,
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
    my $installdst = shift;
    # Data initialization
    my $self  = {
        _permitted => \%fields,
        %fields,
    };
    # Get the install destination from the argument if provided (else see default value above)
    $self->{install_dest} = $installdst || DesignCenter::Config->installtarget || $self->{install_dest};
    die "Need the installation target for creation" unless $self->{install_dest};

    # Convert myself into an object
    bless($self, $class);

    return $self;
}

sub list
  {
    my $self = shift;
    my $terms = shift;
    my $noactivations = shift || 0;

    my $res = {};

    foreach my $repo (@{DesignCenter::Config->repolist}) {
      my @sketches = $self->list_internal($repo, $terms);

      my $contents = CFSketch::repo_get_contents($repo);

      foreach my $sketch (@sketches) {
        # # this format is easy to parse, even if the directory has spaces,
        # # because the first two fields won't have spaces
        # my @docs = grep {
        #   $contents->{$sketch}->{manifest}->{$_}->{documentation}
        # } sort keys %{$contents->{$sketch}->{manifest}};

        # print GREEN, "$sketch", RESET, " $contents->{$sketch}->{fulldir}\n";

        # Create new Sketch object
        $res->{$sketch} = DesignCenter::Sketch->new(%{$contents->{$sketch}});
        # Set installed to its full install location
        $res->{$sketch}->installed($res->{$sketch}->fulldir);
      }
    }

    # Merge activation info
    unless ($noactivations) {
      my $activations = $self->activations;
      foreach my $sketch (sort keys %$activations) {
        next unless exists($res->{$sketch});
        if ('HASH' eq ref $activations->{$sketch}) {
          Util::color_warn "Skipping unusable activations for sketch $sketch!";
          next;
        }
        $res->{$sketch}->_activations($activations->{$sketch});
        $res->{$sketch}->num_instances(scalar(@{$activations->{$sketch}}));
      }
    }

    return $res;
  }

sub list_internal
  {
    my $self  = shift;
    my $repo  = shift;
    my $terms = shift;

    my @ret;

    print "Looking for terms [@$terms] in cf-sketch repository [$repo]\n"
      if DesignCenter::Config->verbose;

    my $contents = CFSketch::repo_get_contents($repo);
    print "Inspecting repo contents: ", DesignCenter::JSON->coder->encode($contents), "\n"
      if DesignCenter::Config->verbose;

    foreach my $sketch (sort keys %$contents) {
      # TODO: improve this search
      my $as_str = $sketch . ' ' . DesignCenter::JSON->coder->encode($contents->{$sketch});

      foreach my $term (@$terms) {
        next unless $as_str =~ m/$term/i;
        push @ret, $sketch;
        last;
      }
    }

    return @ret;
  }

sub activations {
  my $activations = DesignCenter::JSON::load(DesignCenter::Config->actfile, 1);
  unless (defined $activations && ref $activations eq 'HASH') {
    Util::error "Can't load any activations from ".DesignCenter::Config->actfile."\n"
        if DesignCenter::Config->verbose;
    Util::error "There are no configured sketches.\n";
  }
  return $activations;
}

1;
