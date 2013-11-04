# Run::Once version 1

License: MIT
Tags: cfdc, run, once, window, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Run a given script at most once when a given context is true.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: run
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *context* (default: `"any"`, description: Context in which to run)

* parameter _list_ *scripts* (default: none, description: List of scripts to run)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

