# Run::WithData version 1

License: MIT
Tags: cfdc, run, data, json, enterprise_compatible, enterprise_3_6
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Run a given script with the given parameters in a JSON file.

## Dependencies
CFEngine::sketch_template

## API
### bundle: run
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *script* (default: none, description: Script to run)

* parameter _array_ *parameters* (default: `{}`, description: Parameters that will be passed to the script in JSON format as a file argument)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

