# Utilities::ipverify version 1.1

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Execute a bundle if reachable ip has known MAC address

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: maybe_usebundle
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *ip* (default: none, description: none)

* parameter _list_ *maclist* (default: none, description: none)

* parameter _string_ *usebundle* (default: none, description: none)

* parameter _string_ *arp_command* (default: `"/usr/sbin/arp"`, description: none)

* returns _return_ *match* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

