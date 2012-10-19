# cloud_services - Manage cloud services

## AUTHORS
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM

## ## EC2 platform

Anything that supports the Perl CPAN module VM::EC2.

VM::EC2 requires the following CPAN dependencies, which may already be
installed for you:

Module::Build
Digest::SHA
LWP
MIME::Base64
URI::URL
XML::Simple

You can try the programming_languages/cpanm sketch to install VM::EC2,
which will automagically install all its dependencies as well.

## ## VMware platform

Perl in /usr/bin/perl and the VMWare interface programs (`vifs` and
`vmware-cmd`) are required.  You also need a VMWare ESXi server.

See the VMWare website for documents related to ESXi/vSphere 5: http://pubs.vmware.com/vsphere-50/index.jsp

You can also register on that website to download free trial versions of ESXi/vSphere 5 and related software.

## DESCRIPTION

This sketch can manage cloud instances in a generic way.  Right now
EC2 and the VMWare ESXi server are supported.

You specify a few initialization parameters, and then simply say 
"I want to start N instances of class X" or "I want to stop all instances
of class Y".  The "stop" state simply sets N to 0.  An internal Perl
script will take the delta between the desired and the actual instance
count and run or terminate that many instances.

We treat cloud instances as services and accordingly use the
`services` promise type in the `cloud_services` bundle.

## ## Classes

## ## Variables

Please note that `params/demo.json` has all these parameters in one
place, and it's much more convenient to use JSON data to set these
parameters than manually passing them to the `cloud_services` bundle.

* `ec2`: an array with keys specific to the EC2 service.  Any keys
  will be passed to the shim script, but the ones it recognizes today
  are: `ami` (the EC2 AMI to use), `instance_type` (the EC2 instance
  type to use), `region` (the region for the instances, defaults to
  'us-east-1' if you use JSON parameters), `security_policy` (the
  security policy to use, you can try "default" to block all access
  but that will include SSH), `aws_access_key`, `aws_secret_key`, and
  `ssh_pub_key` (self-explanatory).

    "cloudtest_ec2[ami]"             string => "ami-b89842d1";
    "cloudtest_ec2[instance_type]"   string => "m1.small";
    "cloudtest_ec2[region]"          string => "us-east-1";
    "cloudtest_ec2[security_group]"  string => mygroup";
    "cloudtest_ec2[aws_access_key]"  string => "akey1";
    "cloudtest_ec2[aws_secret_key]"  string => "skey1";
    "cloudtest_ec2[ssh_pub_key]"     string => "/path/to/file";

* `vcli`: an array with keys specific to the vcli (VMWare) service.
  You can use `datastore` to indicate the datastore location;
  `fullpath` for the vmfs path; `password` and `user` for
  authentication, and `esxi_server` for the ESXi server's address.
  These parameters are used by the `vifs` and `vmware-cmd` commands.
  Finally you need the `master_image` to know the image to clone, and
  a `child_prefix` to name the clones sequentially.
  `disable_ssl_verify` disables the SSL certificate verification and
  defaults to 0 (false) if you use JSON parameters.

    "cloudtest_vcli[datastore]"           string => "datastore1";
    "cloudtest_vcli[fullpath]"            string => "/vmfs/volumes/4fda02bc-744a4c6e-40f2-08002781db6f";
    "cloudtest_vcli[password]"            string => "cfengine";
    "cloudtest_vcli[user]"                string => "root";
    "cloudtest_vcli[esxi_server]"         string => "10.0.0.1";
    "cloudtest_vcli[master_image]"        string => "ubuntu-12.04-i386-master";
    "cloudtest_vcli[child_prefix]"        string => "ubuntu-12.04-i386-clone-";
    "cloudtest_vcli[disable_ssl_verify]"  string => "1";

* `install_cfengine`: set to 1 to install CFEngine in the EC2 instance
  or 0 not to.  The VMWare integration ignores this parameter.
  
* `stype`: either `vcli` or `ec2`.

* `count`: number of instances to start.

* `class`: a class to set on the new instances.  The VMWare
  integration ignores this parameter.

* `state`: either `start` or `stop`.

* `prefix`: a unique prefix for each execution of `cloud_services`.

* `bundle_home`: the installation directory of the sketch.

## REQUIREMENTS

CFEngine::stdlib (the COPBL)

## SAMPLE USAGE

See `test.cf`.
