# Cloud::Services::AWS::SDB version 1

License: MIT
Tags: cfdc, cloud, aws, sdb
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage AWS SDB domains

## Dependencies
CFEngine::dclib, CFEngine::stdlib, Cloud::Services::Common

## API
### bundle: clear
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *clear_domain* (default: none, description: none)

* parameter _array_ *options* (default: none, description: none)

### bundle: sync
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *datafile* (default: none, description: none)

* parameter _string_ *domain* (default: none, description: none)

* parameter _array_ *options* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

