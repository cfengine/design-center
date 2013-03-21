# Monitoring::SNMP::Walk version 1

License: MIT
Tags: cfdc, snmp
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Do a SNMP walk and translate the results to CFEngine classes and variables

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### walk
* [environment] runenv (default: none)

* [metadata] mymetadata (default: none)

* [string] snmpwalk (default: "/usr/bin/snmpwalk -Oaqt -m ALL -v 2c -c public")

* [string] agent (default: "localhost")

* [string] oid (default: "")

* [return] walked (default: none)

* [return] module_array (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

