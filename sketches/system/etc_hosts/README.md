# System::etc_hosts version 2.2

License: MIT
Tags: cfdc, enterprise_compatible, enterprise_3_6
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage /etc/hosts

## Dependencies
CFEngine::sketch_template

## API
### bundle: configure
* bundle option: name = Set the contents of a hosts file

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *hostfile* (default: `"/etc/hosts"`, description: Location of the hosts file)

* parameter _boolean_ *defined_only* (default: none, description: Keep only the given entries in the hosts file (but note that 127.0.0.1 and localhost are never removed))

* parameter _array_ *hosts* (default: none, description: Map of address keys to host lines)

* returns _return_ *file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

