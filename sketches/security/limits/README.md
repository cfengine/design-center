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
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *filename* (default: `"/etc/security/limits.conf"`)

* _array_ *domains* (default: none)

* _boolean_ *empty_first* (default: `true`)

* _boolean_ *ensure_absent* (default: `false`)

* _return_ *filename* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

