# Repository::EPEL version 1

License: MIT
Tags: cfdc, epel
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sketch for adding EPEL repos to clients

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: ensure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _boolean_ *use_mirrorlist* (default: `"1"`, description: none)

* parameter _boolean_ *update_cache* (default: `"0"`, description: none)

* parameter _string_ *proxy_url* (default: `""`, description: none)

* parameter _string_ *proxy_user* (default: `""`, description: none)

* parameter _string_ *proxy_password* (default: `""`, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

