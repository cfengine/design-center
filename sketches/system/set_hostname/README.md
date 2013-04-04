# System::set_hostname version 1.1

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Configure system hostname

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: set
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *hostname* (default: none, description: none)

* parameter _string_ *domainname* (default: none, description: none)

* returns _return_ *hostname* (default: none, description: none)

* returns _return_ *domainname* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

