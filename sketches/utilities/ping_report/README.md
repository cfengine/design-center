# Utilities::ping_report version 1.2

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Report on pingability of hosts

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: ping
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *hosts* (default: none, description: none)

* parameter _string_ *count* (default: none, description: none)

* returns _return_ *reached* (default: none, description: none)

* returns _return_ *not_reached* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

