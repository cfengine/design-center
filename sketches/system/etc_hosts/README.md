# System::etc_hosts version 2.2

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage /etc/hosts

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: configure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *hostfile* (default: `"/etc/hosts"`, description: none)

* parameter _boolean_ *defined_only* (default: none, description: none)

* parameter _array_ *hosts* (default: none, description: none)

* returns _return_ *file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

