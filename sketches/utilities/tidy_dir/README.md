# Utilities::tidy_dir version 0.01

License: MIT
Tags: cfdc
Authors: Philip J. Freeman <philip.freeman@gmail.com>

## Description
Utility for deleting directory contents as they age. This is a quick sketch to
cleanup the cfengine outputs directory.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: entry
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *prefix* (default: `"__PREFIX__"`, description: none)

* parameter _string_ *dir* (default: `""`, description: The directory to clean up )

* parameter _string_ *days_old* (default: none, description: Files/Dirs older than this will be deleted with reckless abandon ( set to null string to disable.) )

* parameter _boolean_ *recurse* ( default: false, description: Recurse into subdirectories while searching for files. )

## SAMPLE USAGE
See `test.cf` or the example parameters provided

