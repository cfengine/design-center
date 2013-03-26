# Cloud::Services::AWS::EC2 version 1

License: MIT
Tags: cfdc
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage AWS EC2 services

## Dependencies
CFEngine::dclib, CFEngine::stdlib, Cloud::Services::Common

## Parameters
### ensure
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *mymetadata* (default: none, description: none)

* _string_ *count* (default: none, description: none)

* _string_ *ami* (default: none, description: none)

* _string_ *region* (default: `"us-east-1"`, description: none)

* _string_ *type* (default: `"t1.micro"`, description: none)

* _string_ *class* (default: none, description: Logical class to assign to machines)

* _boolean_ *install_cfengine* (default: none, description: none)

* _string_ *hub* (default: none, description: Hub from which the instances should bootstrap)

* _array_ *options* (default: none, description: Options: security_group, netrc, ssh_pub_key.)

* _return_ *instance_count* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

