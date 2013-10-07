# Demo::S3::Deploy version 1.0

License: MIT
Tags: s3, deploy, demo, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Deploy a directory to AWS S3 as simply as possible.

## Dependencies
Cloud::Services::AWS::S3

## API
### bundle: s3deploy
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _boolean_ *enable* (default: `true`, description: Enable this deployment? (if disabled, destroy the S3 bucket))

* parameter _string_ *bucket* (default: none, description: AWS S3 bucket name)

* parameter _string_ *directory* (default: none, description: Directory to deploy into the S3 bucket)

* parameter _string_ *netrc* (default: `"AUTO"`, description: netrc file to use (leave AUTO to use `directory`/../netrc))


## SAMPLE USAGE
See `test.cf` or the example parameters provided

