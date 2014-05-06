# Utilities::Roles version 1.0.0

License: MIT
Tags: cfdc, utilities, roles, enterprise_compatible, enterprise_3_6
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Set system roles from a list

## Dependencies
CFEngine::sketch_template

## API
### bundle: roles
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *role* (default: none, description: Desired system role)

* parameter _list_ *extra_roles* (default: `[]`, description: Other desired system roles, separated by commas)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

