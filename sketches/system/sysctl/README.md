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
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] sysctl_file (default: "/etc/sysctl.conf")

* [boolean] empty_first (default: none)

* [array] ensured_kv (default: none)

* [array] removed_kv (default: none)

* [list] removed_vars (default: none)

* [return] sysctl_file (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

