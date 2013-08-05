# Apache::Simple version 1

License: MIT
Tags: cfdc, webserver, apache
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Install and configure a webserver, e.g. Apache

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## API
### bundle: apache
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *hostname* (default: none, description: Main site host name.)

* parameter _string_ *port* (default: `80`, description: Main site port number.)

* parameter _string_ *ssl_port* (default: `443`, description: Main site SSL port number.)

* parameter _string_ *docroot* (default: none, description: Document root for the main site.)

* parameter _array_ *options* (default: `{"ssl":true}`, description: Apache options.  Provide ssl=1 if you want SSL enabled.)

* returns _return_ *installed* (default: none, description: none)

* returns _return_ *configured* (default: none, description: none)

* returns _return_ *running* (default: none, description: none)

* returns _return_ *docroot* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

