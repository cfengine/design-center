# Demo::SimpleApplication::Deploy version 1.0

License: MIT
Tags: vmware, ensure, deploy, demo, sketchify_generated, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Deploy a full infrastructure for a simple applicationThis is a demo of an application that can deploy vertically across 1 HA hub
(redirecting traffic), 1 memcached worker (pseudo-database), and N web workers
(serving web traffic).  Horizontally the application can be deployed on
OpenStack, EC2, or VMWare, depending on the given type.

The detailed configuration is in `deploy.cf` and intended for customization.
Typically the policy author will know the right EC2 instance type and AMI, or
the VMWare start/stop/count script.  The user-level configuration is simply the
number of web workers, the horizontal (platform) type, and whether the
deployment should be enabled or disabled (stopped).



## Dependencies
Cloud::Services::AWS::EC2, Cloud::Services::OpenStack, Cloud::Services::VMWare, Demo::SimpleApplication

## API
### bundle: deploy
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *workers* (default: none, description: Number of web workers)

* parameter _string_ *type* (default: `"vmware"`, description: Type of deployment: ec2 or openstack or vmware)

* parameter _boolean_ *enable* (default: `true`, description: Enable this deployment? (if disabled, destroy the VMs))


## SAMPLE USAGE
See `test.cf` or the example parameters provided

