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
EC2 and the VMWare ESXi server is supported.

You specify a few initialization parameters, and then simply say 
"I want to start N instances of class X" or "I want to stop all instances
of class Y".  The "stop" state simply sets N to 0.  An internal Perl
script will take the delta between the desired and the actual instance
count and run or terminate that many instances.

We treat cloud instances as services and accordingly use the
`services` promise type in the `cloud_services` bundle.

## ## Classes

* `$(prefix)install_cfengine`: Attempt to install cfengine from the
  official repository.  Only tested for APT.

## ## Variables

* `$(prefix)ec2`: an array with keys specific to the EC2 service.  Any
  keys will be passed to the shim script, but the ones it recognizes
  today are: `ami` (the EC2 AMI to use), `instance_type` (the EC2
  instance type to use), `region` (the region for the instances),
  `security_policy` (the security policy to use, you can try "default"
  to block all access but that will include SSH), `aws_access_key`,
  `aws_secret_key`, and `ssh_pub_key` (self-explanatory).

    "cloud_services_test_ec2[ami]" string => "ami-b89842d1";
    "cloud_services_test_ec2[instance_type]" string => "m1.small";
    "cloud_services_test_ec2[region]" string => "us-east-1";
    "cloud_services_test_ec2[security_group]" string => mygroup";
    "cloud_services_test_ec2[aws_access_key]" string => "akey1";
    "cloud_services_test_ec2[aws_secret_key]" string => "skey1";
    "cloud_services_test_ec2[ssh_pub_key]" string => "/path/to/file";

* `$(prefix)vcli`: an array with keys specific to the vcli (VMWare)
  service.  You can use `datastore` to indicate the datastore
  location; `fullpath` for the vmfs path; `password` and `user` for
  authentication, and `esxi_server` for the ESXi server's address.
  These parameters are used by the `vifs` and `vmware-cmd` commands.
  Finally you need the `master_image` to know the image to clone, and
  a `child_prefix` to name the clones sequentially.

    "cloud_services_vcli_test_vcli[datastore]" string => "datastore1";
    "cloud_services_vcli_test_vcli[fullpath]" string => "/vmfs/volumes/4fda02bc-744a4c6e-40f2-08002781db6f";
    "cloud_services_vcli_test_vcli[password]" string => "cfengine";
    "cloud_services_vcli_test_vcli[user]" string => "root";
    "cloud_services_vcli_test_vcli[esxi_server]" string => "10.0.0.1";
    "cloud_services_vcli_test_vcli[master_image]" string => "ubuntu-12.04-i386-master";
    "cloud_services_vcli_test_vcli[child_prefix]" string => "ubuntu-12.04-i386-clone-";

* `$(prefix)bycontext`: an array with keys that are a context.  This is
  sort of a case statement for CFEngine.  Here we say that for any
  machine, we want to start 1 EC2 instance of class cfworker.
  
    "cloud_services_test_bycontext[any][stype]" string => "ec2";
    "cloud_services_test_bycontext[any][count]" string => "1";
    "cloud_services_test_bycontext[any][class]" string => "cfworker";
    "cloud_services_test_bycontext[any][state]" string => "start";

And here we start 1 VMWare instance, disabling SSL verification.

    "cloud_services_test_bycontext[mine][stype]" string => "vcli";
    "cloud_services_test_bycontext[mine][count]" string => "1";
    "cloud_services_test_bycontext[mine][class]" string => "cfworker";
    "cloud_services_test_bycontext[mine][state]" string => "start";
    "cloud_services_test_bycontext[mine][disable_ssl_verify]" string => "1";

The important and neat thing about `$(prefix)bycontext` is that it is
extensible by you, the user, without modifying the `cloud_services` policy
in `main.cf`.

## REQUIREMENTS

CFEngine::stdlib (the COPBL)

## SAMPLE USAGE

See `test.cf`.
