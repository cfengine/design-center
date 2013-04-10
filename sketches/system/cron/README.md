# System::cron version 2

License: MIT
Tags: cfdc
Authors: Neil H Watson <neil@watson-wilson.ca>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage crontab and /etc/cron.d contents

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: d
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *cron_path* (default: `"/etc/cron.d"`, description: none)

* parameter _string_ *file_task* (default: none, description: none)

* parameter _string_ *runas* (default: `{"function":"getenv","args":["LOGNAME","128"]}`, description: none)

* parameter _string_ *when* (default: none, description: none)

* parameter _list_ *commands* (default: none, description: none)

* returns _return_ *tab* (default: none, description: none)

* returns _return_ *path* (default: none, description: none)

### bundle: tab
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *cron_path* (default: `"/usr/bin/crontab"`, description: none)

* parameter _string_ *line_task* (default: none, description: none)

* parameter _string_ *runas* (default: `{"function":"getenv","args":["LOGNAME","128"]}`, description: none)

* parameter _string_ *when* (default: none, description: none)

* parameter _list_ *commands* (default: none, description: none)

* returns _return_ *tab* (default: none, description: none)

* returns _return_ *path* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

