# Repository::Yum::Maintain version 3

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Create and keep Yum repository metadata up to date

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: manage_metadata
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *name* (default: none, description: none)

* parameter _string_ *path* (default: none, description: none)

* parameter _array_ *perm* (default: none, description: none)

* parameter _string_ *refresh_interval* (default: `60`, description: Refresh interval for the Yum metadata)

* parameter _string_ *createrepo* (default: `"$(default:dc_paths.createrepo)"`, description: Command to create the repo)

* returns _return_ *status* (default: none, description: none)

* returns _return_ *return_code* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

