# System::config_resolver version 1.1

License: MIT
Tags: cfdc, enterprise_compatible, enterprise_3_6
Authors: Nick Anderson <nick@cmdln.org>, Jean Remond <cfengine@remond.re>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Configure DNS resolver

## Dependencies
CFEngine::sketch_template

## API
### bundle: resolver
* bundle option: name = Set up the DNS resolver

* bundle option: single_use = true

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *file* (default: `"/etc/resolv.conf"`, description: Location of the resolver configuration file)

* parameter _list_ *nameserver* (default: none, description: List of DNS servers)

* parameter _list_ *search* (default: none, description: List of DNS search domains (exclusive to 'domain'))

* parameter _list_ *domain* (default: none, description: Default DNS domains (exclusive to 'search'))

* parameter _list_ *options* (default: none, description: List of resolver options)

* parameter _list_ *sortlist* (default: none, description: DNS sortlist (defaults to the natural netmask))

* parameter _list_ *extra* (default: none, description: Extra resolver options, platform-dependent)

* returns _return_ *resolv_conf* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

