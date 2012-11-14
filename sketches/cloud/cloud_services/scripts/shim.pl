#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use MIME::Base64;
use JSON::XS;
my $coder = JSON::XS->new()->relaxed()->utf8()->allow_blessed->convert_blessed->allow_nonref();

$| = 1;                         # autoflush

my %options =
 (
  verbose => 0,
  install_cfengine => 'ON',
  curl => '/usr/bin/curl',
  ec2 => {},
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
 require VM::EC2;

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
  unless (defined $options{ec2}->{$required})
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

 my $ec2 = VM::EC2->new(-access_key => $options{ec2}->{aws_access_key},
                        -secret_key => $options{ec2}->{aws_secret_key},
                        -endpoint => 'http://ec2.amazonaws.com');

 if ($command eq 'control')
 {
  print "ec2 controlling @args\n";
  my ($target_count, $client_class, @rest) = @args;

  my $image = $ec2->describe_images($options{ec2}->{ami});

  # die "Can't authenticate against EC2: please check the AWS secret and access keys";

  # get some information about the image
  my $architecture = $image->architecture;
  my $description  = $image->description || '';
  print "Using image $image with architecture $architecture (desc: '$description')\n";

  my $public_key = $options{ec2}->{ssh_pub_key};

  my $key = $ec2->import_key_pair('shim-ec2-key', $public_key);
  if (!$key)
  {
   die $ec2->error unless $ec2->error =~ /already exists/;
  }

  my @current_instances = find_tagged_ec2_instances($client_class);

  my $delta = $target_count - scalar @current_instances;

  if ($delta > 0)
  {
   my $go = $options{install_cfengine} eq 'ON' ? ec2_init_script($options{hub}, $client_class) : "echo 'Bye now!'";

   my @instances = $image->run_instances(-key_name      =>'shim-ec2-key',
                                         -security_group=> $options{ec2}->{security_group},
                                         -min_count     => $delta,
                                         -max_count     => $delta,
                                         -user_data     => "#!/bin/sh -ex\n$go",
                                         -region        => $options{ec2}->{region},
                                         -client_token  => $ec2->token(),
                                         -instance_type => $options{ec2}->{type})
    or die $ec2->error_str;

   print "waiting for ", scalar @instances, " instances to start up...";
   $ec2->wait_for_instances(@instances);
   print "done!\n";

   foreach my $i (@instances)
   {
    my $status = $i->current_status;
    my $dns    = $i->dnsName;
    print "Started instance $i $dns $status\n";
    my $name = "ec2 instance of class $client_class created by $0";
    $i->add_tag(cfclass => $client_class,
                Name    => $name);
    print "Tagged instance $i: Name = '$name', cfclass = $client_class\n";
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
   my $todo = shift @current_instances;
   stop_and_terminate_ec2_instances([$todo]);
   $delta++;
  }
 }
 elsif ($command eq 'down')
 {
  my $client_class = shift @args;

  die "Not enough arguments given to 'ec2 $command': expecting CLIENT_CLASS"
   unless defined $client_class;

  my @instances = find_tagged_ec2_instances($client_class);
  if (scalar @instances)
  {
   stop_and_terminate_ec2_instances(\@instances);
  }
 }
 elsif ($command eq 'run')
 {
  my $client_class = shift @args;
  my $command = shift @args;

  die "Not enough arguments given to 'ec2 $command': expecting CLIENT_CLASS COMMAND"
   unless defined $command;

  my @instances = find_tagged_ec2_instances($client_class);
  if (scalar @instances)
  {
   system ("$command " . $_->dnsName) foreach @instances;
  }
 }
 elsif ($command eq 'list' || $command eq 'console' || $command eq 'console-tail' || $command eq 'list-full' || $command eq 'count')
 {
  my $client_class = shift @args;

  die "Not enough arguments given to 'ec2 $command': expecting CLIENT_CLASS"
   unless defined $client_class;
  my @instances = find_tagged_ec2_instances($client_class);
  if ($command eq 'count')
  {
   print scalar @instances, "\n";
  }
  elsif ($command eq 'console')
  {
   foreach my $i (@instances)
   {
    my $out = $i->console_output;
    my $dns    = $i->dnsName;
    print "$i $dns\n$out\n\n";
   }
  }
  elsif ($command eq 'console-tail')
  {
   while (1)
   {
    foreach my $i (@instances)
    {
     my $out = $i->console_output;
     my $dns    = $i->dnsName;
     print "$i $dns\n$out\n\n";
    }
   }
   print "Press Ctrl-C to abort the tail...";
  }
  elsif ($command eq 'list-full')
  {
   foreach my $i (@instances)
   {
    my $status = $i->current_status;
    my $dns    = $i->dnsName;
    print "$i $dns $status\n";
   }
  }
  else
  {
   print join("\n", @instances), "\n";
  }
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
  my $servers = curl_openstack('list');
  foreach my $server (sort { $a->{name} cmp $b->{name} } @$servers)
  {
   printf("id=%s image=%s ip=%-15s progress=%03d%% sname=%s\n",
          $coder->encode($server->{id}),
          $coder->encode($server->{image}),
          $server->{ip},
          $server->{progress},
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
  my ($target_count, $client_class, @rest) = @args;

  my $servers = curl_openstack('list');

  my @clients = grep {
   $_->{name} ne $options{openstack}->{master} &&
     $_->{image} eq $options{openstack}->{image}
    } @$servers;

  printf "Got clients %s\n", $coder->encode(\@clients);

  my @current_instances = @clients;
  my $current_count = scalar @current_instances;
  my $delta = $target_count - $current_count;

  if ($delta > 0)
  {
   print "waiting for 1 instance to start up...";
   wait_for_openstack_create($current_count+1, $client_class);
   print "done!\n";
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
   my $todo = shift @current_instances;
   curl_openstack('delete', $todo->{id});
  }
 }
}
else
{
 die "Sorry, can't handle shim mode $shim_mode";
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
                   )
     {
      my $k = shift @$v;
      $server_data->{$k} = hashref_search($server, @$v);
     }

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

 die curl_openstack('create',
                    {
                     server =>
                     {
                      name => "$client_class-" . ($start+1),
                      imageRef => $options{openstack}->{image},
                      flavorRef => $options{openstack}->{flavor},
                      "OS-DCF:diskConfig" => "AUTO",
                      metadata => { cfmaster => $options{openstack}->{master} },
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

sub find_tagged_ec2_instances
{
 my $tag = shift @_;
 my $state = shift @_ || 'running';

 return $ec2->describe_instances(-filter => {
                                             'instance-state-name'=>$state,
                                             'tag:cfclass' => $tag
                                            });
}

sub stop_and_terminate_ec2_instances
{
 my $instances = shift @_;

 my @instances = @$instances;

 print "Stopping instances @instances...";
 $ec2->stop_instances(-instance_id=>$instances,-force=>1);
 $ec2->wait_for_instances(@instances);
 print "done!\n";

 print "Terminating instances @instances...";
 $ec2->terminate_instances(-instance_id=>$instances,-force=>1);
 $ec2->wait_for_instances(@instances);
 print "done!\n";
}

sub ec2_init_script
{
 my $hub_ip = shift @_;
 my $client_class = shift @_;

 return "
LOG=/tmp/shim.ec2.cfengine.setup.log

echo '000 Bootstrapping host of class $client_class (adding class shim_ec2) to hub $hub_ip.' >> \$LOG 2>&1

echo '$hub_ip' > /var/tmp/cfhub.ip
echo '$client_class' > /var/tmp/cfclass
echo 'shim_ec2' >> /var/tmp/cfclass

echo '001 Adding the CFEngine APT repo and installing cfengine-community' >> \$LOG 2>&1

curl -o /tmp/cfengine.gpg.key http://cfengine.com/pub/gpg.key >> \$LOG 2>&1

apt-key add /tmp/cfengine.gpg.key >> \$LOG 2>&1

add-apt-repository http://cfengine.com/pub/apt >> \$LOG 2>&1

(apt-get update || echo anyways...) >> \$LOG 2>&1

(apt-get install -y --force-yes cfengine-community || echo anyways...) >> \$LOG 2>&1

# this is version 3.1.5, quite old!
# apt-get install cfengine3 >> \$LOG 2>&1

" . ec2_client_init_script($client_class);

}

sub ec2_client_init_script
{
 # from JH's magic
 return '

echo "002 Installing the persistent classes from /var/tmp/cfclass" >> $LOG 2>&1

cat >> /tmp/set_persistent_classes.cf << EOF;
body common control {
  bundlesequence => { "set_persistent_classes" };
  nova_edition|constellation_edition::
    host_licenses_paid => "1";
}

bundle agent set_persistent_classes {
  vars:
    "classes" slist => readstringlist("/var/tmp/cfclass", "#[^n]*", "\s*\n\s*", "100000", "99999999999");
    "now" int => ago(0,0,0,0,0,0);
  reports:
    cfengine_3::
      "\$(classes) \$(now)"
        classes => if_repaired_persist_forever("\$(classes)");
}
body classes if_repaired_persist_forever(class) {
  promise_repaired => { "\$(class)" };
  persist_time => "48417212";
  timer_policy => "reset";
}
EOF

/var/cfengine/bin/cf-agent -KI -f /tmp/set_persistent_classes.cf >> $LOG 2>&1

rm -rf /tmp/set_persistent_classes.cf >> $LOG 2>&1

echo "003 Bootstrap to the policy hub" >> $LOG 2>&1

echo "Normally we would rm -rf /var/cfengine/inputs" >> $LOG 2>&1

/var/cfengine/bin/cf-agent -B -s `cat /var/tmp/cfhub.ip` >> $LOG 2>&1
';
}
