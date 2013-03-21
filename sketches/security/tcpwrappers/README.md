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
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *allow_filename* (default: `"/etc/hosts.allow"`, description: none)

* _string_ *deny_filename* (default: `"/etc/hosts.allow"`, description: none)

* _array_ *allow* (default: none, description: none)

* _array_ *deny* (default: none, description: none)

* _boolean_ *empty_first* (default: `true`, description: none)

* _boolean_ *ensure_absent* (default: `false`, description: none)

* _return_ *allow_filename* (default: none, description: none)

* _return_ *deny_filename* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

