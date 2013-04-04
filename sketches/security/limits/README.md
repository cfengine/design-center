# Security::security_limits version 1.2

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Configure /etc/security/limits.conf

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: limits
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *filename* (default: `"/etc/security/limits.conf"`, description: none)

* parameter _array_ *domains* (default: none, description: none)

* parameter _boolean_ *empty_first* (default: `true`, description: none)

* parameter _boolean_ *ensure_absent* (default: `false`, description: none)

* returns _return_ *filename* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

