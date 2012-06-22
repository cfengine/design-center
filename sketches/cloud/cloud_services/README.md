# cloud_services - Manage cloud services

## AUTHORS
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM

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

## DESCRIPTION

This sketch can manage cloud instances in a generic way.  Right now EC2 is supported.

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

* `$(prefix)bycontext`: an array with keys that are a context.  This is
  sort of a case statement for CFEngine.  Here we say that for any
  machine, we want to start 1 EC2 instance of class cfworker.
  
    "cloud_services_test_bycontext[any][stype]" string => "ec2";
    "cloud_services_test_bycontext[any][count]" string => "1";
    "cloud_services_test_bycontext[any][class]" string => "cfworker";
    "cloud_services_test_bycontext[any][state]" string => "start";

The important and neat thing about `$(prefix)bycontext` is that it is
extensible by you, the user, without modifying the `cloud_services` policy
in `main.cf`.

## REQUIREMENTS

CFEngine::stdlib (the COPBL)

## SAMPLE USAGE

See `test.cf`.
