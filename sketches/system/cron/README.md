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
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] cron_path (default: "/etc/cron.d")

* [string] file_task (default: none)

* [string] runas (default: {"function":"getenv","args":["LOGNAME","128"]})

* [string] when (default: none)

* [list] commands (default: none)

* [return] tab (default: none)

* [return] path (default: none)

### tab
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] cron_path (default: "/usr/bin/crontab")

* [string] line_task (default: none)

* [string] runas (default: {"function":"getenv","args":["LOGNAME","128"]})

* [string] when (default: none)

* [list] commands (default: none)

* [return] tab (default: none)

* [return] path (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

