# Utilities::tidy_dir version 0.01

License: MIT
Tags: cfdc
Authors: Philip J Freeman <philip.freeman@gmail.com>

## Description
Simple sketch to tidy a directory

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: tidy_dir
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *dir* (default: none, description: The directory to clean up)

* parameter _string_ *days_old* (default: `""`, description: Files/Dirs older than this will be deleted with reckless abandon ( set to null string to disable.))

* parameter _boolean_ *recurse* (default: `""`, description: recurse into subdirectories while searching for files.)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

