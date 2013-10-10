# Data::Triggers::Github version 1.0

License: MIT
Tags: classes, trigger, notification, github, sketchify_generated, persistent, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Trigger behavior from a Github Atom feed to deploy to S3
# Purpose

Data::Triggers::Github shows how to handle external notifications with Github.

## Github triggers

The configuration is minimal: you provide a `url` pointing to a Github repo, a
`branch`, and a `s3_bucket` to upload into.  So, for the example URL
`https://github.com/tzz/jim` (having a file `jim.pl in branch `master`) and S3
bucket `tzz_jim_bucket` you would ultimately have `jim.pl` uploaded to
https://s3.amazonaws.com/tzz_jim_bucket/jim.pl

You can provide a netrc file, which simply has this format:

```
machine AWS username yourname login yourpublickey password yourprivatekey
```

If you don't specify it, that file defaults to `~/.netrc` as evaluated by the
account that runs cf-agent (/root/.netrc typically).  Note that the file can be
GnuPG-encrypted (indicated by a `.gpg` extension) in which case you need
`gpg-agent` running and to read the GnuPG manual.  Whether encrypted or not, at
least make the file readable only to the account that runs cf-agent.



## Dependencies
CFEngine::stdlib, Cloud::Services::AWS::S3, VCS::vcs_mirror

## API
### bundle: github
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *url* (default: none, description: Base URL of Github repo, e.g. https://github.com/cfengine/vagrant-cfe)

* parameter _string_ *branch* (default: `"master"`, description: branch of Github repo)

* parameter _string_ *s3_bucket* (default: none, description: S3 bucket to deploy into)

* parameter _string_ *netrc* (default: `"~/.netrc"`, description: netrc file, see README.md)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

