# Repository::apt::Maintain version 1

License: MIT
Tags: cfdc
Authors: Jean Remond <cfengine@remond.re>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage deb repositories in /etc/apt/sources.list.d/ files or /etc/apt/sources.list

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: ensure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *file* (default: `"/etc/apt/sources.list"`, description: none)

* parameter _string_ *url* (default: none, description: none)

* parameter _string_ *distribution* (default: none, description: none)

* parameter _list_ *components* (default: none, description: none)

* parameter _list_ *types* (default: none, description: none)

* parameter _string_ *options* (default: `""`, description: none)

* returns _return_ *file* (default: none, description: none)

### bundle: wipe
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _boolean_ *wipe* (default: none, description: none)

* parameter _string_ *file* (default: none, description: none)

* returns _return_ *file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

