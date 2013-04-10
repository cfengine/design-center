# System::sysctl version 1.5

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage sysctl values

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: set
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *sysctl_file* (default: `"/etc/sysctl.conf"`, description: none)

* parameter _boolean_ *empty_first* (default: none, description: none)

* parameter _array_ *ensured_kv* (default: none, description: none)

* parameter _array_ *removed_kv* (default: none, description: none)

* parameter _list_ *removed_vars* (default: none, description: none)

* returns _return_ *sysctl_file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

