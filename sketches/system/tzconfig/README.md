# System::tzconfig version 1.3

License: MIT
Tags: cfdc, enterprise_compatible, enterprise_3_6
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage system timezone configuration

## Dependencies
CFEngine::sketch_template

## API
### bundle: set
* bundle option: name = Set the timezone

* bundle option: single_use = true

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *timezone* (default: none, description: Time zone)

* parameter _string_ *zoneinfo_dir* (default: `"/usr/share/zoneinfo"`, description: Directory of zoneinfo data files)

* returns _return_ *timezone* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

