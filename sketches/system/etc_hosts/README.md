# System::etc_hosts version 2.2

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage /etc/hosts

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### configure
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *hostfile* (default: `"/etc/hosts"`, description: none)

* _boolean_ *defined_only* (default: none, description: none)

* _array_ *hosts* (default: none, description: none)

* _return_ *file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

