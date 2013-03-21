# Cloud::Services::AWS version 1

License: MIT
Tags: cfdc
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage AWS services

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### EC2
* _environment_ *runenv* (default: none)

* _metadata_ *mymetadata* (default: none)

* _string_ *count* (default: none)

* _string_ *ami* (default: none)

* _string_ *region* (default: `"us-east-1"`)

* _string_ *type* (default: `"t1.micro"`)

* _string_ *class* (default: none)

* _boolean_ *install_cfengine* (default: none)

* _string_ *hub* (default: none)

* _array_ *options* (default: none)

* _return_ *instance_count* (default: none)

* _return_ *instances* (default: none)

### S3_clear
* _environment_ *runenv* (default: none)

* _metadata_ *mymetadata* (default: none)

* _string_ *s3_clear_bucket* (default: none)

* _array_ *options* (default: none)

### S3_sync
* _environment_ *runenv* (default: none)

* _metadata_ *mymetadata* (default: none)

* _string_ *directory* (default: none)

* _string_ *s3_bucket* (default: none)

* _array_ *options* (default: none)

### SDB_clear
* _environment_ *runenv* (default: none)

* _metadata_ *mymetadata* (default: none)

* _string_ *sdb_clear_bucket* (default: none)

* _array_ *options* (default: none)

### SDB_sync
* _environment_ *runenv* (default: none)

* _metadata_ *mymetadata* (default: none)

* _string_ *directory* (default: none)

* _string_ *sdb_bucket* (default: none)

* _array_ *options* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

