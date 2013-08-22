# Demo::SimpleApplication version 1.0

License: MIT
Tags: vmworld2013, demo, sketchify_generated, enterprise_compatible
Authors: Nick Anderson <nick.anderson@cfengine.com>, Ted Zlatanov <ted.zlatanov@cfengine.com>, Diego Zamboni <diego.zamboni@cfengine.com>

## Description
Configures hosts for a simple application consisting of webworkers (Apache + simple static content), haworkers (haproxy dynamically configured to use the existing webworkers) and mcworkers (memcached)

## Dependencies
none

## API
### bundle: configure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

