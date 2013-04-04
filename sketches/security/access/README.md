# System::access version 1

License: MIT
Tags: cfdc, security, access, access.conf
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage access.conf values

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: set
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *access_file* (default: `"/etc/security/access.conf"`, description: none)

* parameter _boolean_ *empty_first* (default: none, description: none)

* parameter _list_ *ensured_lines* (default: none, description: none)

* parameter _list_ *removed_patterns* (default: none, description: none)

* returns _return_ *access_file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

