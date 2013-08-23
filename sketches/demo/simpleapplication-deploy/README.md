# Demo::SimpleApplication::Deploy version 1.0

License: MIT
Tags: vmware, ensure, deploy, demo, sketchify_generated
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Deploy a full infrastructure for a simple application

## Dependencies
Cloud::Services::VMWare, Demo::SimpleApplication

## API
### bundle: deploy
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *workers* (default: none, description: Number of web workers)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

