# System::config_resolver version 1.1

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Jean Remond <cfengine@remond.re>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Configure DNS resolver

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### resolver
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] file (default: "/etc/resolv.conf")

* [list] nameserver (default: none)

* [list] search (default: none)

* [list] domain (default: none)

* [list] options (default: none)

* [list] sortlist (default: none)

* [list] extra (default: none)

* [return] resolv_conf (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

