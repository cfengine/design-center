# Users::Local version 1

License: MIT
Tags: cfdc, users
Authors: Nick Anderson <nick@cmdln.org>

## Description
Sketch for managing local users

## Dependencies
CFEngine::dclib, CFEngine::stdlib, CFEngine::stdlib::3.5.0

## API
### bundle: local
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _array_ *users* (default: none, description: none)

* parameter _array_ *options* (default: `{"groupname":"defaultgroup"}`, description: none)

### bundle: runbased
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *checker* (default: `"/usr/bin/id"`, description: Command to run to check if a user exists.)

* parameter _array_ *users* (default: none, description: none)

* parameter _array_ *options* (default: `{"groupname":"defaultgroup"}`, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

