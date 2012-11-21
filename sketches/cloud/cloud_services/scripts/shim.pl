#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use MIME::Base64;
use JSON::XS;
use FindBin;
my $coder = JSON::XS->new()->relaxed()->utf8()->allow_blessed->convert_blessed->allow_nonref();

$| = 1;                         # autoflush

my %options =
 (
  verbose => 0,
  install_cfengine => 'ON',
  curl => '/usr/bin/curl',
  ec2 => {
          entry_url => 'http://ec2.amazonaws.com',
          aws_tool => "$FindBin::Bin/aws",
         },
  openstack => {
                flavor => "2",
                entry_url => 'https://identity.api.rackspacecloud.com/v2.0/tokens',
                password => 'do not -- try !! this',
               },
 );

my @options_spec =
 (
  "verbose",
  "hub=s",
  "curl=s",
  "install_cfengine=s",
  "ec2=s%",
  "openstack=s%",
 );

GetOptions (
            \%options,
            @options_spec,
           );

my $shim_mode = shift @ARGV;

die "Syntax: $0 [--curl=/bin/curl --hub=xyz --ec2 ec2option=x --openstack openstackoption=y] [ec2|openstack] [command] [arguments]"
 unless defined $shim_mode;

my $ec2 = $shim_mode eq 'ec2';
my $openstack = $shim_mode eq 'openstack';

my $command = shift @ARGV;
my @args = @ARGV;

if ($ec2)
{
 foreach my $required (qw/ssh_pub_key ami instance_type region security_group/)
 {
  die "Sorry, we can't go on until you've specified --ec2 $required"
   unless defined $options{ec2}->{$required};
 }

 # Access and secret key inherited from environment if defined
 foreach my $required (qw/aws_access_key aws_secret_key/)
 {
  my $envvarname = uc($required);
  $envvarname =~ s/^AWS_/EC2_/;
  if (defined $options{ec2}->{$required})
  {
   $ENV{$envvarname} = $options{ec2}->{$required};
  }
  else
  {
   if (defined $ENV{$envvarname})
   {
    $options{ec2}->{$required} = $ENV{$envvarname};
   }
   else
   {
    die "Sorry, we can't go on until you've specified --ec2 $required (or specified it in your $envvarname environment variable)";
   }
  }
 }

 if (-r $options{ec2}->{ssh_pub_key})
 {
  open my $ef, '<', $options{ec2}->{ssh_pub_key} or die "Could not open environment pass-through file $options{ec2}->{ssh_pub_key}: $!";
  my $line = <$ef>;
  chomp $line;
  $options{ec2}->{ssh_pub_key} = $line;
 }

 if ($command eq 'list' || $command eq 'count')
 {
  my $cfclass = shift @args || 'cfworker';
  my $servers = aws_ec2('list', $cfclass);
  if ($command eq 'count')
  {
   print scalar @$servers, "\n";
  }
  else
  {
   foreach my $server (sort { $a->{name} cmp $b->{name} } @$servers)
   {
    printf("id=%s image=%s ip=%-15s progress=%03d%% cfclass=%s sname=%s\n",
           $coder->encode($server->{id}),
           $coder->encode($server->{image}),
           $server->{ip},
           $server->{progress},
           $server->{cfclass},
           $server->{name});
   }
  }
 }
 elsif ($command eq 'control')
 {
  print "ec2 controlling @args\n";
  my ($target_count, $cfclass, @rest) = @args;

  my $servers = aws_ec2('list', $cfclass);

  generic_control($servers,
                  $target_count,
                  sub { wait_for_ec2_create(shift, $cfclass) },
                  sub { aws_ec2('delete', shift) });
 }
 else
 {
  print "unknown ec2 command: $command @args\n";
 }
}
elsif ($openstack)
{
 die "Sorry, we can't go on until you've specified --hub=HUB"
  unless defined $options{hub};

  foreach my $required (qw/user key image master/)
 {
  die "Sorry, we can't go on until you've specified --openstack $required"
   unless defined $options{openstack}->{$required};
 }

 my $token = curl_openstack('token');
 printf "Got token %s\n", $token if $options{verbose};

 if ($command eq 'list')
 {
  my ($cfclass, @rest) = @args;
  my $servers = curl_openstack('list', $cfclass);

  foreach my $server (sort { $a->{name} cmp $b->{name} } @$servers)
  {
   printf("id=%s image=%s ip=%-15s progress=%03d%% cfclass=%s sname=%s\n",
          $coder->encode($server->{id}),
          $coder->encode($server->{image}),
          $server->{ip},
          $server->{progress},
          $server->{cfclass},
          $server->{name});
  }
 }
 elsif ($command eq 'ssh')
 {
  my $goto = shift @args;
  die "$0: openstack ssh command requires a machine name argument"
   unless defined $goto;

  my $servers = curl_openstack('list');
  foreach my $server (@$servers)
  {
   if ($server->{name} eq $goto)
   {
    if ($server->{ip})
    {
     exec "ssh root\@$server->{ip}";
    }
    else
    {
     die "$goto has no IPv4 address";
    }
   }
  }

  die "Could not SSH to $goto, it's not in the machine list";
 }
 elsif ($command eq 'control')
 {
  print "openstack controlling @args\n";
  my ($target_count, $cfclass, @rest) = @args;

  my $servers = curl_openstack('list', $cfclass);
  my @clients = grep {
   $_->{name} ne $options{openstack}->{master}
    } @$servers;
  printf "Got clients %s\n", $coder->encode(\@clients);
  generic_control(\@clients,
                  $target_count,
                  sub { wait_for_openstack_create(shift, $cfclass) },
                  sub { curl_openstack('delete', shift) });
 }
 else
 {
  print "unknown openstack command: $command @args\n";
 }
}
else
{
 die "Sorry, can't handle shim mode $shim_mode";
}

sub aws_ec2
{
 my $mode = shift @_;
 my @args = @_;

 my $tool = $options{ec2}->{aws_tool};
 my $run;
 my $t;

 my $ret;

 if ($mode eq 'list')
 {
  $run = "$tool --json describe-instances";
  open $t, "$run|" or die "Could not get server list with command [$run]: $!";;
 }
 elsif ($mode eq 'create-tags')
 {
  my $tags = $args[1];
  my $extra = join ' ', map { "--tag $_=$tags->{$_}" } keys %$tags;
  $run = "$tool --json create-tags $args[0] $extra";
  open $t, "$run|" or die "Could not create tags with command [$run]: $!";;
 }
 elsif ($mode eq 'delete')
 {
  $run = "$tool --json terminate-instances $args[0]";
  open $t, "$run|" or die "Could not kill instances with command [$run]: $!";;
 }
 elsif ($mode eq 'create')
 {
  # [--group SecurityGroup...|-g SecurityGroup...] [--key KeyName|-k KeyName] [--user-data UserData|-d UserData] [--user-data-file UserData|-f UserData] [-a AddressingType] [--instance-type InstanceType|--type InstanceType|-t InstanceType|-i InstanceType] [--availability-zone Placement.AvailabilityZone|-z Placement.AvailabilityZone] [--kernel KernelId] [--ramdisk RamdiskId] [--block-device-mapping |-b ] [--device-name DeviceName...] [--no-device NoDevice...] [--virtual-name VirtualName...] [--snapshot SnapshotId...|-s SnapshotId...] [--volume-size VolumeSize...] [--delete-on-termination DeleteOnTermination...] [--monitor Monitoring.Enabled...|-m Monitoring.Enabled...] [--disable-api-termination DisableApiTermination...] [--instance-initiated-shutdown-behavior InstanceInitiatedShutdownBehavior...] [--placement-group Placement.GroupName...] [--subnet SubnetId...|-s SubnetId...] [--private-ip-address PrivateIpAddress...] [--client-token ClientToken...]

  $run = sprintf("$tool --json run-instances %s -g %s -t %s --region %s",
                 $options{ec2}->{ami},
                 $options{ec2}->{security_group},
                 $options{ec2}->{instance_type},
                 $options{ec2}->{region});
  # TODO: use --ec2 ssh_pub_key, --hub, and --install_cfengine
  open $t, "$run|" or die "Could not create instances with command [$run]: $!";;
 }
 else
 {
  die "Unknown EC2 mode $mode";
 }

 print "Running [$run]\n" if $options{verbose};

 while (<$t>)
 {
  print "$_\n" if $options{verbose};
  my $data;
  eval
  {
   $data = $coder->decode($_);
  };

  if (defined $data)
  {
   if ($mode eq 'list')
   {
    $ret = [];

    my $server_wrappers = hashref_search($data, qw/reservationSet item/);

    die "Could not find server instances in aws data"
     unless (defined $server_wrappers && ref $server_wrappers eq 'ARRAY');

    foreach my $server_wrapper (@$server_wrappers)
    {
     my $server = hashref_search($server_wrapper, qw/instancesSet item/);

     unless (defined $server && ref $server eq 'HASH')
     {
      warn "Could not find server instance in malformed instanceSet aws data " .
       $coder->encode($server_wrapper);
      next;
     }

     my $server_data = { };

     foreach my $v (
                    [ name => qw/tagSet item Name/ ],
                    [ cfclass => qw/tagSet item cfclass/ ],
                    [ id => qw/instanceId/ ],
                    [ ip => qw/ipAddress/ ],
                    [ image => qw/imageId/ ],
                    [ progress => qw/instanceState name/ ],
                   )
     {
      my $k = shift @$v;
      $server_data->{$k} = hashref_search($server, @$v);

      # extract key-value pairs from the tags
      $server_data->{$k} = $server_data->{$k}->{value}
       if (ref $server_data->{$k} eq 'HASH' &&
           exists $server_data->{$k}->{value});

     }

     my $p = $server_data->{progress} || 'unknown';
     if ($p eq 'running')
     {
      $server_data->{progress} = 100;
     }
     elsif ($p eq 'terminated')
     {
      $server_data->{progress} = -99;
     }
     else
     {
      $server_data->{progress} = 0;
     }

     $server_data->{ip} ||= '0.0.0.0';

     $server_data->{name} = $server_data->{id}
      unless defined $server_data->{name};

     die "Could not find imageId in instance data, giving up"
      unless defined $server_data->{id};


     # filtering below
     my $cfclass = $server_data->{cfclass} || '???';
     my $name = $server_data->{name} || '???';

     unless ($server_data->{cfclass} &&
             $server_data->{cfclass} eq $args[0])
     {
      print "Skipping '$name': its class $cfclass doesn't match $args[0]\n"
       if $options{verbose};
      next;
     }

     # terminated EC2 instances remain visible for at least an hour; skip them
     if ($server_data->{progress} < 0)
     {
      print "Skipping '$name': it is terminated\n"
       if $options{verbose};
      next;
     }

     push @$ret, $server_data;
    }
   }
   elsif ($mode eq 'create-tags')
   {
    $ret = $data;
   }
   elsif ($mode eq 'delete')
   {
    $ret = $data;
   }
   elsif ($mode eq 'create')
   {
    my $id = hashref_search($data, qw/instancesSet item instanceId/);
    $ret = [$data, $id];
    if ($id)
    {
     my $tagret = aws_ec2('create-tags',
                          $id,
                          { Name => $args[1], cfclass => $args[0] });
     $ret = [$data, $id, $tagret];
    }
   }
  }
 }

 return $ret;
}

sub wait_for_ec2_create
{
 my $start = shift @_;
 my $client_class = shift @_;

 return aws_ec2('create', $client_class, "$client_class-$start");
}

sub curl_openstack
{
 my $mode = shift @_;
 my $args = shift @_;

 my $run;
 my $uri;
 my $method_option = '';
 my $data_option = '';

 if ($mode eq 'token')
 {
  $method_option = '-X POST';
$run = <<EOHIPPUS;
$options{curl} -s $method_option $options{openstack}->{entry_url} -d '{ "auth":{ "RAX-KSKEY:apiKeyCredentials":{ "username":"$options{openstack}->{user}", "apiKey":"$options{openstack}->{key}" } } }' -H "Content-type: application/json" |
EOHIPPUS
 }
 elsif ($mode eq 'list')
 {
  $uri = '/servers/detail';
 }
 elsif ($mode eq 'create')
 {
  $uri = '/servers';
  $method_option = '-X POST';
  $data_option = sprintf("-d '%s'", $coder->encode($args));
 }
 elsif ($mode eq 'delete')
 {
  $uri = "/servers/$args";
  $method_option = '-X DELETE';
 }
 else
 {
  die "Unknown curl_openstack mode $mode, exiting";
 }

 if (!defined $run)
 {
  $run = <<EOHIPPUS;
$options{curl} -s $method_option $options{url}/$uri -H "X-Auth-Token: $options{token}" -H "Content-type: application/json" $data_option |
EOHIPPUS
 }

 print "Running: $run\n" if $options{verbose};
 open my $c, $run or die "Could not run command [$run]: $!";

 while (<$c>)
 {
  print if $options{verbose};
  my $data;
  eval
  {
   $data = $coder->decode($_);
  };
  # print Dumper $data;
  if ($mode eq 'token')
  {
   my $token = hashref_search($data, qw/access token id/);
   die "Couldn't get security token through [$run]!" unless defined $token;
   $options{auth} = $data;
   # we would use service => 'compute' but that also matches 1st
   # generation servers, so we match on the name specifically
   $options{catalog} = hashref_search($options{auth},
                                      qw/access serviceCatalog/,
                                      { name => 'cloudServersOpenStack' } );

   die "Couldn't find service catalog" unless defined $options{catalog};

   $options{endpoint} = hashref_search($options{catalog},
                                       qw/endpoints/,
                                       { publicURL => undef });
   $options{url} = hashref_search($options{endpoint}, qw/publicURL/);

   $options{token} = $token;
   return $token;
  }
  elsif ($mode eq 'list')
  {
   $options{servers} = hashref_search($data, qw/servers/);
   if ($options{servers} && ref $options{servers} eq 'ARRAY')
   {
    my $servers = [];
    foreach my $server (@{$options{servers}})
    {
     my $name = hashref_search($server, qw/name/);
     die "Could not determine name for server " . $coder->encode($server)
      unless defined $name;
     my $server_data = { name => $name };

     foreach my $v (
                    [ id => qw/id/ ],
                    [ ip => qw/accessIPv4/ ],
                    [ image => qw/image id/ ],
                    [ progress => qw/progress/ ],
                    [ cfclass => qw/metadata cfclass/ ],
                   )
     {
      my $k = shift @$v;
      $server_data->{$k} = hashref_search($server, @$v);
     }

     $server_data->{cfclass} ||= '???';

     push @$servers, $server_data;
    }
    return $servers;
   }
   else
   {
    die "Could not get server list with command [$run]: data=" . $coder->encode($data);
   }
  }
  elsif ($mode eq 'create')
  {
   return $data;
  }
  elsif ($mode eq 'delete')
  {
   return $data;
  }
  die Dumper [$run, $data];
 }
}

sub wait_for_openstack_create
{
 my $start = shift @_;
 my $client_class = shift @_;

 my $hub64 = encode_base64($options{hub});
 chomp $hub64;

 return curl_openstack('create',
                       {
                        server =>
                        {
                         name => "$client_class-" . ($start+1),
                         imageRef => $options{openstack}->{image},
                         flavorRef => $options{openstack}->{flavor},
                         "OS-DCF:diskConfig" => "AUTO",
                         metadata => { cfmaster => $options{openstack}->{master}, cfclass => $client_class },
                         adminPass => $options{openstack}->{password},
                        },

                        # this is broken on the RackSpace side, ticket opened
                        personality =>
                        [
                         {
                          path => "/etc/cfhub",
                          contents => $hub64
                         }
                        ],
                       }
                      );
}

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

sub generic_control
{
 my $servers      = shift @_;
 my $target_count = shift @_;
 my $creator      = shift @_;
 my $deleter      = shift @_;

 my $current_count = scalar @$servers;
 my $delta = $target_count - $current_count;

 if ($delta > 0)
 {
  print "waiting for 1 instance to start up...";
  my $cdata = $creator->($current_count+1);
  print 'Got creation data ' , $coder->encode($cdata), "\n"
   if $options{verbose};
  my $error = hashref_search($cdata, qw/Errors Error/);

  if ($error)
  {
   printf("error: %s (%s)\n",
          hashref_search($error, 'Code'),
          hashref_search($error, 'Message'));
  }
  else
  {
   print "done!\n";
  }
 }
  elsif ($delta == 0)
  {
   print "Nothing to do, we have $target_count instances already\n";
  }
  else                                  # delta < 0, we need to decom
  {
   # Note the race condition: if a machine is shut down externally,
   # we won't know about it... so we just shut down 1 at a time and
   # expect repeated runs to converge.  This race is really hard to
   # avoid in a distributed system (you're basically trying to count
   # a distributed resource), so gentle convergence is safer.
   print "waiting for 1 instance to shut down...";
   $deleter->($servers->[0]->{id});
  }
}

# sub ec2_init_script
# {
#  my $hub_ip = shift @_;
#  my $client_class = shift @_;

#  return "
# LOG=/tmp/shim.ec2.cfengine.setup.log

# echo '000 Bootstrapping host of class $client_class (adding class shim_ec2) to hub $hub_ip.' >> \$LOG 2>&1

# echo '$hub_ip' > /var/tmp/cfhub.ip
# echo '$client_class' > /var/tmp/cfclass
# echo 'shim_ec2' >> /var/tmp/cfclass

# echo '001 Adding the CFEngine APT repo and installing cfengine-community' >> \$LOG 2>&1

# curl -o /tmp/cfengine.gpg.key http://cfengine.com/pub/gpg.key >> \$LOG 2>&1

# apt-key add /tmp/cfengine.gpg.key >> \$LOG 2>&1

# add-apt-repository http://cfengine.com/pub/apt >> \$LOG 2>&1

# (apt-get update || echo anyways...) >> \$LOG 2>&1

# (apt-get install -y --force-yes cfengine-community || echo anyways...) >> \$LOG 2>&1

# # this is version 3.1.5, quite old!
# # apt-get install cfengine3 >> \$LOG 2>&1

# " . ec2_client_init_script($client_class);

# }

# sub ec2_client_init_script
# {
#  # from JH's magic
#  return '

# echo "002 Installing the persistent classes from /var/tmp/cfclass" >> $LOG 2>&1

# cat >> /tmp/set_persistent_classes.cf << EOF;
# body common control {
#   bundlesequence => { "set_persistent_classes" };
#   nova_edition|constellation_edition::
#     host_licenses_paid => "1";
# }

# bundle agent set_persistent_classes {
#   vars:
#     "classes" slist => readstringlist("/var/tmp/cfclass", "#[^n]*", "\s*\n\s*", "100000", "99999999999");
#     "now" int => ago(0,0,0,0,0,0);
#   reports:
#     cfengine_3::
#       "\$(classes) \$(now)"
#         classes => if_repaired_persist_forever("\$(classes)");
# }
# body classes if_repaired_persist_forever(class) {
#   promise_repaired => { "\$(class)" };
#   persist_time => "48417212";
#   timer_policy => "reset";
# }
# EOF

# /var/cfengine/bin/cf-agent -KI -f /tmp/set_persistent_classes.cf >> $LOG 2>&1

# rm -rf /tmp/set_persistent_classes.cf >> $LOG 2>&1

# echo "003 Bootstrap to the policy hub" >> $LOG 2>&1

# echo "Normally we would rm -rf /var/cfengine/inputs" >> $LOG 2>&1

# /var/cfengine/bin/cf-agent -B -s `cat /var/tmp/cfhub.ip` >> $LOG 2>&1
# ';
# }
