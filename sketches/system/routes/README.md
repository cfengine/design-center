# System::Routes version 1

License: MIT
Tags: cfdc, routes, iptables
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sets defaults and user permissions in the sudoers file

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: ensure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _array_ *static_routes* (default: none, description: none)

* parameter _boolean_ *purge_routes* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

