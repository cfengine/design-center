# Demo::S3::Deploy version 1.0

License: MIT
Tags: s3, deploy, demo, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Deploy a directory to AWS S3 as simply as possible.
This sketch will synchronize a `directory` to a S3 `bucket` or clear the
`bucket` (depending on whether `enabled` is set).

You only need to provide the `bucket` name and the `directory` name.  The files
will be uploaded with the `public-read` ACL.

In addition you need to provide a `netrc` file location.  When that file has a
line in this format:

```
machine AWS username yourname login yourpublickey password yourprivatekey
```

all the AWS interactions will be authenticated with that public and private key
combination.

As an example, for bucket `velocity` and directory `/root/data` with a file
`/root/data/1/image.jpg`, you'll see the image uploaded in
https://s3.amazonaws.com/velocity/1/image.jpg

(Typically the bucket name maps to a single web site for your static assets.)


## Dependencies
Cloud::Services::AWS::S3

## API
### bundle: s3deploy
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _boolean_ *enable* (default: `true`, description: Enable this deployment? (if disabled, destroy the S3 bucket))

* parameter _string_ *bucket* (default: none, description: AWS S3 bucket name)

* parameter _string_ *directory* (default: none, description: Directory to deploy into the S3 bucket)

* parameter _string_ *netrc* (default: `"~/.netrc"`, description: netrc file to use (see documentation for format))


## SAMPLE USAGE
See `test.cf` or the example parameters provided

