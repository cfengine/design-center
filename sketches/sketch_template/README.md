# CFEngine::sketch_template version 2.00

License: MIT
Tags: cfdc
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Standard template for Design Center sketches

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: entry
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *prefix* (default: `"__PREFIX__"`, description: none)

* parameter _boolean_ *myboolean* (default: `"1"`, description: none)

* parameter _string_ *mytype* (default: `"fallback"`, description: none)

* parameter _string_ *myip* (default: none, description: This is my IP address or whatever)

* parameter _list_ *mylist* (default: none, description: none)

* parameter _array_ *myarray* (default: none, description: none)

* returns _return_ *myreturn* (default: none, description: none)

* returns _return_ *myreturn2* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

