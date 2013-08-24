# System::syslog version 1

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>, Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com, Diego Zamboni <diego.zamboni@cfengine.com>

## Description
Manage syslog configuration

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: set
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *syslog_file* (default: `"/etc/rsyslog.conf"`, description: none)

* parameter _boolean_ *empty_first* (default: none, description: none)

* parameter _array_ *ensured_kv* (default: none, description: none)

* parameter _array_ *removed_kv* (default: none, description: none)

* parameter _list_ *removed_vars* (default: none, description: none)

* returns _return_ *syslog_file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

