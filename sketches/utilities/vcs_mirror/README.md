# VCS::vcs_mirror version 1.12

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Check out and update a VCS repository.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: mirror
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *vcs* (default: none, description: none)

* parameter _string_ *path* (default: none, description: none)

* parameter _string_ *origin* (default: none, description: none)

* parameter _string_ *branch* (default: none, description: none)

* parameter _array_ *options* (default: none, description: none)

* returns _return_ *deploy_path* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

