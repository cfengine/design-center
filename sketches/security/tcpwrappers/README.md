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
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *allow_filename* (default: `"/etc/hosts.allow"`)

* _string_ *deny_filename* (default: `"/etc/hosts.allow"`)

* _array_ *allow* (default: none)

* _array_ *deny* (default: none)

* _boolean_ *empty_first* (default: `true`)

* _boolean_ *ensure_absent* (default: `false`)

* _return_ *allow_filename* (default: none)

* _return_ *deny_filename* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

