# Run::Once version 1

License: MIT
Tags: cfdc, run, once, window, enterprise_compatible, enterprise_3_6
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Run a given script at most once when a given context is true.

## Dependencies
CFEngine::sketch_template

## API
### bundle: run
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *context* (default: `"any"`, description: Context in which to run OR file with classes or hostnames in which to run)

* parameter _list_ *scripts* (default: none, description: List of scripts to run.  If an element is a file, use that file as TXT or CSV)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

