# Applications::NewRelic version 1

License: MIT
Tags: cfdc, newrelic, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Sketch for installing, configuring, and starting New Relic monitoring plugins (only server monitoring supported at the moment).

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: server
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *license_key* (default: `"not valid"`, description: New Relic license key)

* parameter _boolean_ *ensure* (default: `true`, description: Ensure server monitoring service is running.  Set to false to stop service.)

* parameter _boolean_ *install* (default: `true`, description: Install packages.  Set to false to remove them.)

* returns _return_ *installed* (default: none, description: none)

* returns _return_ *configured* (default: none, description: none)

* returns _return_ *running* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

