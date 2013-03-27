# Cloud::Services::AWS::S3 version 1

License: MIT
Tags: cfdc, cloud, aws, s3
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage AWS S3 buckets

## Dependencies
CFEngine::dclib, CFEngine::stdlib, Cloud::Services::Common

## Parameters
### clear
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *mymetadata* (default: none, description: none)

* _string_ *clear_bucket* (default: none, description: none)

* _array_ *options* (default: none, description: none)

### sync
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *mymetadata* (default: none, description: none)

* _string_ *directory* (default: none, description: none)

* _string_ *bucket* (default: none, description: none)

* _array_ *options* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

