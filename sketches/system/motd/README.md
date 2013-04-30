# System::motd version 1.00

License: MIT
Tags: cfdc
Authors: Ben Heilman <bheilman@enova.com

## Description
Configure the Message of the Day

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: entry
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *message* (default: none, description: Static message to print at login (aka MOTD))

* parameter _boolean_ *static* (default: `"0"`, description: Install a static motd)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

