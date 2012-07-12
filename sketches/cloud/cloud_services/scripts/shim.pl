#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use VM::EC2;
use Getopt::Long;

$| = 1;                         # autoflush

my %options =
 (
  install_cfengine => 'ON',
  ec2 => {},
 );

my @options_spec =
 (
  "hub=s",
  "install_cfengine=s",
  "ec2=s%",
 );

GetOptions (
            \%options,
            @options_spec,
           );


foreach my $required (qw/aws_access_key aws_secret_key ssh_pub_key ami instance_type region security_group/)
{
 die "Sorry, we can't go on until you've specified --ec2 $required"
  unless defined $options{ec2}->{$required};
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

my $shim_mode = shift @ARGV;

die "Sorry, can't handle shim mode $shim_mode" unless $shim_mode eq 'ec2';

my $command = shift @ARGV;
my @args = @ARGV;

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
 if (!$key) {
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
 else                                   # delta < 0, we need to decom
 {
  while ($delta < 0)
  {
   my $todo = shift @current_instances;
   stop_and_terminate_ec2_instances([$todo]);
   $delta++;
  }
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
