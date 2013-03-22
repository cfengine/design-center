# Monitoring::SNMP::Walk version 1

License: MIT
Tags: cfdc, snmp
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Do a SNMP walk and translate the results to CFEngine classes and variables

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## Parameters
### walk
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *mymetadata* (default: none, description: none)

* _string_ *snmpwalk* (default: `"/usr/bin/snmpwalk -Oaqt -m ALL -v 2c -c public"`, description: Command line to execute 'snmpwalk' (with options).  Note that '-Oaqt' is required and '-m ALL' is highly recommended.)

* _string_ *agent* (default: `"localhost"`, description: Agent to target, e.g. a host name or IP address)

* _string_ *oid* (default: `""`, description: OID to walk)

* _return_ *walked* (default: none, description: Was the tree walked?  Boolean.)

* _return_ *module_array* (default: none, description: Name of array defined by the 'walk' bundle)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

