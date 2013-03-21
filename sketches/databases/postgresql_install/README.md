# Database::Install::PostgreSQL version 1.1

License: MIT
Tags: cfdc
Authors: Nakarin Phooripoom <nakarin.phooripoom@cfengine.com>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Install and enable the PostgreSQL database engine

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### ensure
* _environment_ *runenv* (default: none)

* _metadata_ *mymetadata* (default: none)

* _boolean_ *server* (default: none)

* _boolean_ *purge* (default: `false`)

* _list_ *extra_packages* (default: `[]`)

* _boolean_ *use_only_extra_packages* (default: `false`)

* _return_ *installed* (default: none)

* _return_ *running* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

