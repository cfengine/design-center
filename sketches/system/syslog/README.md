# System::Syslog version 1

License: MIT
Tags: cfdc
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Configures syslog

## Dependencies
CFEngine::stdlib

## API
### bundle: system_syslog
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *conf_file* (default: `"/etc/syslog.conf"`, description: none)

* parameter _array_ *config* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

