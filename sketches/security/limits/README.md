# Security::security_limits version 1.2

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Configure /etc/security/limits.conf

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### limits
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] filename (default: "/etc/security/limits.conf")

* [array] domains (default: none)

* [boolean] empty_first (default: true)

* [boolean] ensure_absent (default: false)

* [return] filename (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

