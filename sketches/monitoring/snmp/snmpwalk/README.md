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
* _environment_ *runenv* (default: none)

* _metadata_ *mymetadata* (default: none)

* _string_ *snmpwalk* (default: `"/usr/bin/snmpwalk -Oaqt -m ALL -v 2c -c public"`)

* _string_ *agent* (default: `"localhost"`)

* _string_ *oid* (default: `""`)

* _return_ *walked* (default: none)

* _return_ *module_array* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

