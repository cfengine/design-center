# System::sysctl version 1.5

License: MIT
Tags: cfdc, enterprise_compatible, enterprise_3_6
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage sysctl values

## Dependencies
CFEngine::sketch_template

## API
### bundle: set
* bundle option: name = Set up the sysctl contents

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *sysctl_file* (default: `"/etc/sysctl.conf"`, description: sysctl configuration file)

* parameter _boolean_ *empty_first* (default: `false`, description: none)

* parameter _array_ *ensured_kv* (default: none, description: Parameters that must be in the sysctl)

* parameter _array_ *removed_kv* (default: `{"unwantedvar":"unwantedsetting"}`, description: Specific key-value combinations to be removed (regular expressions allowed))

* parameter _list_ *removed_vars* (default: `["nosuchvar"]`, description: Specific variables to be removed (regular expressions allowed))

* returns _return_ *sysctl_file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

