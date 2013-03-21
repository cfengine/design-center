# Utilities::abortclasses version 1.7

License: MIT
Tags: cfdc
Authors: Ben Heilman <bheilman@enova.com>, Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Abort execution if a certain file exists, aka 'Cowboy mode'

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### abortclasses_filebased
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] abortclass (default: none)

* [string] trigger_file (default: "/COWBOY")

* [boolean] alert_only (default: false)

* [string] trigger_context (default: "any")

* [array] timeout (default: {"hours":24,"years":0,"minutes":0,"action":"abortclasses_timeout_action_noop","months":0,"enabled":false,"days":0})


## SAMPLE USAGE
See `test.cf` or the example parameters provided

