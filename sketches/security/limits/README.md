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
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *filename* (default: `"/etc/security/limits.conf"`, description: none)

* _array_ *domains* (default: none, description: none)

* _boolean_ *empty_first* (default: `true`, description: none)

* _boolean_ *ensure_absent* (default: `false`, description: none)

* _return_ *filename* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

