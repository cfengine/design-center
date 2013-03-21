# Repository::apt::Maintain version 1

License: MIT
Tags: cfdc
Authors: Jean Remond <cfengine@remond.re>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage deb repositories in /etc/apt/sources.list.d/ files or /etc/apt/sources.list

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### ensure
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *file* (default: `"/etc/apt/sources.list"`)

* _string_ *url* (default: none)

* _string_ *distribution* (default: none)

* _list_ *components* (default: none)

* _list_ *types* (default: none)

* _string_ *options* (default: `""`)

* _return_ *file* (default: none)

### wipe
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _boolean_ *wipe* (default: none)

* _string_ *file* (default: none)

* _return_ *file* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

