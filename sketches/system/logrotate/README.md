# System::Logrotate version 1

License: MIT
Tags: cfdc, logrotate
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sets defaults and user permissions in the sudoers file

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: run
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *conf_dir* (default: none, description: none)

* parameter _array_ *logrotate_globals* (default: none, description: none)

* parameter _array_ *logrotate_descriptions* (default: none, description: none)

* parameter _boolean_ *logrotate_purge* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

