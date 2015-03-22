# Run::Dropdir version 1

License: MIT
Tags: cfdc, run, dropdir, window, enterprise_compatible, enterprise_3_6
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Run the scripts in a directory for a limited time when a given context is true and report their output in the 'dropdir' bundle.  Clean out outdated scripts.  Requires three or more letters in the script name

## Dependencies
CFEngine::sketch_template

## API
### bundle: dropdir_run
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *context* (default: `"any"`, description: Context in which to run)

* parameter _string_ *directory* (default: none, description: Drop directory (put scripts to be run here))

* parameter _string_ *days* (default: `7`, description: Number of days to keep the scripts)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

