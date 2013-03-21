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
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] hostfile (default: "/etc/hosts")

* [boolean] defined_only (default: none)

* [array] hosts (default: none)

* [return] file (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

