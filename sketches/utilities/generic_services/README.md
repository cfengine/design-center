# Services::Generic version 1

License: MIT
Tags: cfdc
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Control services in a generic way

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## API
### bundle: ensure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *name* (default: none, description: none)

* parameter _string_ *start* (default: none, description: startcommand)

* parameter _string_ *stop* (default: none, description: stopcommand)

* parameter _string_ *pattern* (default: none, description: none)

* parameter _string_ *policy* (default: none, description: none)

* returns _return_ *policy_implemented* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

