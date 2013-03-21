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
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *file* (default: `"/etc/resolv.conf"`, description: none)

* _list_ *nameserver* (default: none, description: none)

* _list_ *search* (default: none, description: none)

* _list_ *domain* (default: none, description: none)

* _list_ *options* (default: none, description: none)

* _list_ *sortlist* (default: none, description: none)

* _list_ *extra* (default: none, description: none)

* _return_ *resolv_conf* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

