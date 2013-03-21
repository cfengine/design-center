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
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *cron_path* (default: `"/etc/cron.d"`, description: none)

* _string_ *file_task* (default: none, description: none)

* _string_ *runas* (default: `{"function":"getenv","args":["LOGNAME","128"]}`, description: none)

* _string_ *when* (default: none, description: none)

* _list_ *commands* (default: none, description: none)

* _return_ *tab* (default: none, description: none)

* _return_ *path* (default: none, description: none)

### tab
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *cron_path* (default: `"/usr/bin/crontab"`, description: none)

* _string_ *line_task* (default: none, description: none)

* _string_ *runas* (default: `{"function":"getenv","args":["LOGNAME","128"]}`, description: none)

* _string_ *when* (default: none, description: none)

* _list_ *commands* (default: none, description: none)

* _return_ *tab* (default: none, description: none)

* _return_ *path* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

