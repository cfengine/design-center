# Utilities::abortclasses version 1.7

License: MIT
Tags: cfdc
Authors: Ben Heilman <bheilman@enova.com>, Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Abort execution if a certain file exists, aka 'Cowboy mode'

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: abortclasses_filebased
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *abortclass* (default: none, description: none)

* parameter _string_ *trigger_file* (default: `"/COWBOY"`, description: none)

* parameter _boolean_ *alert_only* (default: `false`, description: none)

* parameter _string_ *trigger_context* (default: `"any"`, description: none)

* parameter _array_ *timeout* (default: `{"hours":24,"years":0,"minutes":0,"action":"abortclasses_timeout_action_noop","months":0,"enabled":false,"days":0}`, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

