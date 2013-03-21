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
* [environment] runenv (default: none)

* [metadata] mymetadata (default: none)

* [string] count (default: none)

* [string] ami (default: none)

* [string] region (default: "us-east-1")

* [string] type (default: "t1.micro")

* [string] class (default: none)

* [boolean] install_cfengine (default: none)

* [string] hub (default: none)

* [array] options (default: none)

* [return] instance_count (default: none)

* [return] instances (default: none)

### S3_clear
* [environment] runenv (default: none)

* [metadata] mymetadata (default: none)

* [string] s3_clear_bucket (default: none)

* [array] options (default: none)

### S3_sync
* [environment] runenv (default: none)

* [metadata] mymetadata (default: none)

* [string] directory (default: none)

* [string] s3_bucket (default: none)

* [array] options (default: none)

### SDB_clear
* [environment] runenv (default: none)

* [metadata] mymetadata (default: none)

* [string] sdb_clear_bucket (default: none)

* [array] options (default: none)

### SDB_sync
* [environment] runenv (default: none)

* [metadata] mymetadata (default: none)

* [string] directory (default: none)

* [string] sdb_bucket (default: none)

* [array] options (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

