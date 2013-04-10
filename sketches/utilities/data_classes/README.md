# Data::Classes version 1

License: MIT
Tags: cfdc, data, classes
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Define classes from data

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: byfile
* parameter _string_ *classname* (default: none, description: *Global* class to define if all the `files` exist.)

* parameter _list_ *files* (default: none, description: List of files that must all exist for the `classname` to be defined)

* returns _return_ *defined* (default: none, description: none)

### bundle: byport
* parameter _string_ *classname* (default: none, description: *Global* class to define if all the `ports` have listeners.)

* parameter _list_ *ports* (default: none, description: List of ports that must all have a listener for the `classname` to be defined)

* returns _return_ *defined* (default: none, description: none)

### bundle: byprocess
* parameter _string_ *classname* (default: none, description: *Global* class to define if all the `process_patterns` are matched.)

* parameter _list_ *process_patterns* (default: none, description: List of process patterns that must all match in the process table for the `classname` to be defined)

* parameter _string_ *owner* (default: `""`, description: If not empty, require this owner of the processes for the `classname` to be defined)

* parameter _string_ *min_process_count* (default: `1`, description: Required minimum count of processes for the `classname` to be defined)

* parameter _string_ *max_process_count* (default: `1000000`, description: Required maximum count of processes for the `classname` to be defined (default is very large))

* returns _return_ *defined* (default: none, description: none)

### bundle: byshell
* parameter _string_ *classname* (default: none, description: *Global* class to define if all the `commands` run OK.)

* parameter _list_ *commands* (default: none, description: List of commands that must all run OK for the `classname` to be defined)

* returns _return_ *defined* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

