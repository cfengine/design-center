# Services::Generic version 1

License: MIT
Tags: cfdc
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Control services in a generic way

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## Parameters
### ensure
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *name* (default: none, description: none)

* _string_ *start* (default: none, description: startcommand)

* _string_ *stop* (default: none, description: stopcommand)

* _string_ *pattern* (default: none, description: none)

* _string_ *policy* (default: `"start"`, description: Indicate desired service state: start, stop)

* _return_ *policy_implemented* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

