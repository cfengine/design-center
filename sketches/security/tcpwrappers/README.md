# Security::tcpwrappers version 1.2

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage /etc/hosts.{allow,deny}

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### set
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] allow_filename (default: "/etc/hosts.allow")

* [string] deny_filename (default: "/etc/hosts.allow")

* [array] allow (default: none)

* [array] deny (default: none)

* [boolean] empty_first (default: true)

* [boolean] ensure_absent (default: false)

* [return] allow_filename (default: none)

* [return] deny_filename (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

