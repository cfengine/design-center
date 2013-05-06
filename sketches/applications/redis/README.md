# Applications::Redis version 1

License: MIT
Tags: cfdc
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description


## Dependencies
CFEngine::stdlib

## API
### bundle: applications_redis
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *pidfile* (default: `"/var/run/redis.pid"`, description: none)

* parameter _string_ *port* (default: `"6379"`, description: none)

* parameter _string_ *address* (default: `"0.0.0.0"`, description: none)

* parameter _string_ *timeout* (default: `"0"`, description: none)

* parameter _string_ *dbfilename* (default: `"dump.rdb"`, description: none)

* parameter _string_ *datadir* (default: `"/var/lib/redis"`, description: none)

* parameter _string_ *logfile* (default: `"/var/log/redis/redis.log"`, description: none)

* parameter _string_ *glueoutputbuf* (default: `"yes"`, description: none)

* parameter _string_ *shareobjectspoolsize* (default: `"disabled"`, description: none)

* parameter _string_ *masterserver* (default: `"0.0.0.0"`, description: none)

* parameter _string_ *masterport* (default: `"0"`, description: none)

* parameter _list_ *saves* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

