# System::cron version 2

License: MIT
Tags: cfdc
Authors: Neil H Watson <neil@watson-wilson.ca>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage crontab and /etc/cron.d contents

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### d
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *cron_path* (default: `"/etc/cron.d"`)

* _string_ *file_task* (default: none)

* _string_ *runas* (default: `{"function":"getenv","args":["LOGNAME","128"]}`)

* _string_ *when* (default: none)

* _list_ *commands* (default: none)

* _return_ *tab* (default: none)

* _return_ *path* (default: none)

### tab
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *cron_path* (default: `"/usr/bin/crontab"`)

* _string_ *line_task* (default: none)

* _string_ *runas* (default: `{"function":"getenv","args":["LOGNAME","128"]}`)

* _string_ *when* (default: none)

* _list_ *commands* (default: none)

* _return_ *tab* (default: none)

* _return_ *path* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

