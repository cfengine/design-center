# System::tzconfig version 1.3

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage system timezone configuration

## Dependencies
CFEngine::dclib

## API
### bundle: set
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *timezone* (default: none, description: none)

* parameter _string_ *zoneinfo* (default: none, description: none)

* returns _return_ *timezone* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

