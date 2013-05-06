# Applications::Memcached version 1

License: MIT
Tags: cfdc, memcached
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sketch for installing, configuring, and starting memcached.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: server
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *port* (default: `"11211"`, description: none)

* parameter _string_ *user* (default: `"nobody"`, description: none)

* parameter _string_ *maxconn* (default: `"1024"`, description: none)

* parameter _string_ *cachesize* (default: `"64"`, description: none)

* parameter _string_ *listen* (default: `"0.0.0.0"`, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

