# Cloud::Services::OpenStack version 1

License: MIT
Tags: cfdc, cloud, openstack
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage OpenStack services
This sketch will start or stop OpenStack compute instances.

You have to provide it some basic parameters such as the template ID.  Also you
provide a class name for the new machines and a target count.

In addition in the `options` array you can provide a netrc file.  When that file
has a line in this format:

```
machine OpenStack username yourname login yourpublickey password yourprivatekey
```

all the OpenStack interactions will be authenticated with that public and
private key combination.


## Dependencies
CFEngine::dclib, CFEngine::stdlib, Cloud::Services::Common

## API
### bundle: ensure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *count* (default: none, description: none)

* parameter _string_ *class* (default: none, description: Logical class to assign to machines)

* parameter _boolean_ *install_cfengine* (default: none, description: none)

* parameter _string_ *hub* (default: none, description: Hub from which the instances should bootstrap)

* parameter _array_ *options* (default: none, description: Options: security_group, netrc, ssh_pub_key.)

* returns _return_ *instance_count* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

