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
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] file (default: "/etc/apt/sources.list")

* [string] url (default: none)

* [string] distribution (default: none)

* [list] components (default: none)

* [list] types (default: none)

* [string] options (default: "")

* [return] file (default: none)

### wipe
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [boolean] wipe (default: none)

* [string] file (default: none)

* [return] file (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

