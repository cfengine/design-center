# Database::Install::SQLite version 1.1

License: MIT
Tags: cfdc
Authors: Nakarin Phooripoom <nakarin.phooripoom@cfengine.com>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Install and enable the SQLite database engine

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### ensure
* [environment] runenv (default: none)

* [metadata] mymetadata (default: none)

* [boolean] purge (default: false)

* [list] extra_packages (default: [])

* [boolean] use_only_extra_packages (default: false)

* [return] installed (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

