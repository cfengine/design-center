# Database::Install::MySQL version 1

License: MIT
Tags: cfdc
Authors: Nakarin Phooripoom <nakarin.phooripoom@cfengine.com>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Install and enable the MySQL database engine

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## API
### bundle: ensure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _boolean_ *server* (default: none, description: none)

* parameter _boolean_ *purge* (default: `false`, description: none)

* parameter _list_ *extra_packages* (default: `[]`, description: none)

* parameter _boolean_ *use_only_extra_packages* (default: `false`, description: none)

* returns _return_ *installed* (default: none, description: none)

* returns _return_ *running* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

