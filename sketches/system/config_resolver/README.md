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
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *file* (default: `"/etc/resolv.conf"`)

* _list_ *nameserver* (default: none)

* _list_ *search* (default: none)

* _list_ *domain* (default: none)

* _list_ *options* (default: none)

* _list_ *sortlist* (default: none)

* _list_ *extra* (default: none)

* _return_ *resolv_conf* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

