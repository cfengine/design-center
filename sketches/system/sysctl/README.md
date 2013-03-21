# System::sysctl version 1.5

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage sysctl values

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### set
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *sysctl_file* (default: `"/etc/sysctl.conf"`)

* _boolean_ *empty_first* (default: none)

* _array_ *ensured_kv* (default: none)

* _array_ *removed_kv* (default: none)

* _list_ *removed_vars* (default: none)

* _return_ *sysctl_file* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

