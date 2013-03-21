# Utilities::ipverify version 1.1

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Execute a bundle if reachable ip has known MAC address

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### maybe_usebundle
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *ip* (default: none, description: none)

* _list_ *maclist* (default: none, description: none)

* _string_ *usebundle* (default: none, description: none)

* _string_ *arp_command* (default: `"/usr/sbin/arp"`, description: none)

* _return_ *match* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

