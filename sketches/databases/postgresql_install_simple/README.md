# Database::Install::PostgreSQL::Simple version 1.1

License: MIT
Tags: cfdc, database, postgresql, enterprise_compatible
Authors: Nakarin Phooripoom <nakarin.phooripoom@cfengine.com>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Install and enable the PostgreSQL database engine

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## API
### bundle: simple
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* returns _return_ *installed* (default: none, description: none)

* returns _return_ *running* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

