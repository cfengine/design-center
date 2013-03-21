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
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *file* (default: `"/etc/apt/sources.list"`, description: none)

* _string_ *url* (default: none, description: none)

* _string_ *distribution* (default: none, description: none)

* _list_ *components* (default: none, description: none)

* _list_ *types* (default: none, description: none)

* _string_ *options* (default: `""`, description: none)

* _return_ *file* (default: none, description: none)

### wipe
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _boolean_ *wipe* (default: none, description: none)

* _string_ *file* (default: none, description: none)

* _return_ *file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

