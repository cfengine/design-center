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
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] ip (default: none)

* [list] maclist (default: none)

* [string] usebundle (default: none)

* [string] arp_command (default: "/usr/sbin/arp")

* [return] match (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

