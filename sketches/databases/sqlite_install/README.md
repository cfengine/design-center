# Database::Install::SQLite version 1.1

License: MIT
Tags: cfdc
Authors: Nakarin Phooripoom <nakarin.phooripoom@cfengine.com>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Install and enable the SQLite database engine

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### ensure
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *mymetadata* (default: none, description: none)

* _boolean_ *purge* (default: `false`, description: none)

* _list_ *extra_packages* (default: `[]`, description: none)

* _boolean_ *use_only_extra_packages* (default: `false`, description: none)

* _return_ *installed* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

