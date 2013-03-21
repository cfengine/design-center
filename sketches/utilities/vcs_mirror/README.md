# VCS::vcs_mirror version 1.12

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Check out and update a VCS repository.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### mirror
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] vcs (default: none)

* [string] path (default: none)

* [string] origin (default: none)

* [string] branch (default: none)

* [array] options (default: none)

* [return] deploy_path (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

