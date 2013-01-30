#!/usr/bin/perl

BEGIN
{
 if (-l $0)
 {
  require FindBin;
  $0 = readlink $0;
  FindBin->again();
 }
}

use FindBin;
use lib "$FindBin::Bin/../lib/cf-sketch", "$FindBin::Bin/../lib/cf-sketch/File-Which-1.09/lib", "$FindBin::Bin/../lib/cf-sketch/JSON-2.53/lib", "$FindBin::Bin/perl-lib", "$FindBin::Bin/perl-lib/File-Which-1.09/lib", "$FindBin::Bin/perl-lib/JSON-2.53/lib";

use warnings;
use strict;
use JSON;
use File::Which;

use Util;
use constant SKETCH_DEF_FILE => 'sketch.json';

$| = 1;                         # autoflush

my $coder = JSON->new()->relaxed()->utf8()->allow_nonref();
# for storing JSON data so it's directly comparable
my $canonical_coder = JSON->new()->canonical()->utf8()->allow_nonref();
my $curl = which('curl');

unless ($curl)
{
 api_exit_error("$0: could not locate `curl' executable in $ENV{PATH}");
}

my $config_file = shift @ARGV;

unless ($config_file)
{
 api_exit_error("Syntax: $0 CONFIG_FILE");
}

my ($config, @errors) = load($config_file);

unless ($config)
{
 api_exit_error("$0 could not load $config_file");
}

sub api_ok
{
  print coder->encode(make_ok(@_)), "\n";
}

sub api_exit_error
{
 api_error(@_);
 exit 0;
}

sub api_error
{
  print coder->encode(make_error(@_)), "\n";
}

sub make_ok
{
 return { api_ok => shift };
}

sub make_error
{
 return { api_error => [@_] };
}

sub load
{
 my $f = shift @_;

 my @j;

 my $try_eval;
 eval
 {
  $try_eval = $coder->decode($f);
 };

 if ($try_eval) # detect inline content, must be proper JSON
 {
  @j = split "\n", $f;
 }
 elsif (Util::is_resource_local($f))
 {
  my $j;
  unless (open($j, '<', $f) && $j)
  {
   return (undef, "Could not inspect $f: $!");
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
                my $parent = load($include);
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

# sub get
# {
#  return curl('GET', @_);
# }

# sub curl
# {
#  my $mode = shift @_;
#  my $url = shift @_;

#  my $run = <<EOHIPPUS;
# $curl -s $mode $url |
# EOHIPPUS

#  print STDERR "Running: $run\n";
#  open my $c, $run or die "Could not run command [$run]: $!";

#  while (<$c>)
#  {
#   print if $options{verbose};
#   my $data;
#   eval
#   {
#    $data = $coder->decode($_);
#   };
#   # print Dumper $data;
#   if ($mode eq 'token')
#   {
#    my $token = hashref_search($data, qw/access token id/);
#    die "Couldn't get security token through [$run]!" unless defined $token;
#    $options{auth} = $data;
#    # we would use service => 'compute' but that also matches 1st
#    # generation servers, so we match on the name specifically
#    $options{catalog} = hashref_search($options{auth},
#                                       qw/access serviceCatalog/,
#                                       { name => 'cloudServersOpenStack' } );

#    die "Couldn't find service catalog" unless defined $options{catalog};

#    $options{endpoint} = hashref_search($options{catalog},
#                                        qw/endpoints/,
#                                        { publicURL => undef });
#    $options{url} = hashref_search($options{endpoint}, qw/publicURL/);

#    $options{token} = $token;
#    return $token;
#   }
#   elsif ($mode eq 'list')
#   {
#    $options{servers} = hashref_search($data, qw/servers/);
#    if ($options{servers} && ref $options{servers} eq 'ARRAY')
#    {
#     my $servers = [];
#     foreach my $server (@{$options{servers}})
#     {
#      my $name = hashref_search($server, qw/name/);
#      die "Could not determine name for server " . $coder->encode($server)
#       unless defined $name;
#      my $server_data = { name => $name };

#      foreach my $v (
#                     [ id => qw/id/ ],
#                     [ ip => qw/accessIPv4/ ],
#                     [ image => qw/image id/ ],
#                     [ progress => qw/progress/ ],
#                     [ cfclass => qw/metadata cfclass/ ],
#                    )
#      {
#       my $k = shift @$v;
#       $server_data->{$k} = hashref_search($server, @$v);
#      }

#      $server_data->{cfclass} ||= '???';

#      push @$servers, $server_data;
#     }
#     return $servers;
#    }
#    else
#    {
#     die "Could not get server list with command [$run]: data=" . $coder->encode($data);
#    }
#   }
#   elsif ($mode eq 'create')
#   {
#    return $data;
#   }
#   elsif ($mode eq 'delete')
#   {
#    return $data;
#   }
#   die Dumper [$run, $data];
#  }
# }

sub hashref_search
{
 my $ref = shift @_;
 my $k = shift @_;
 if (ref $ref eq 'HASH' && exists $ref->{$k})
 {
  if (scalar @_ > 0) # dig further
  {
   return hashref_search($ref->{$k}, @_);
  }
  else
  {
   return $ref->{$k};
  }
 }

 if (ref $ref eq 'ARRAY' && ref $k eq 'HASH') # search an array
 {
  foreach my $item (@$ref)
  {
   foreach my $probe (keys %$k)
   {
    if (ref $item eq 'HASH' &&
        exists $item->{$probe})
    {
     # if the value is undef...
     return $item unless defined $k->{$probe};
     # or it matches the probe
     return $item if $item->{$probe} eq $k->{$probe};
    }
   }
  }
 }

 return undef;
}

# 1;
