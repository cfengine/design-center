# Applications::NewRelic version 1

License: MIT
Tags: cfdc, newrelic
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Sketch for installing, configuring, and starting New Relic.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: server
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *license_key* (default: `"not valid"`, description: none)

* returns _return_ *installed* (default: none, description: none)

* returns _return_ *configured* (default: none, description: none)

* returns _return_ *restarted* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

