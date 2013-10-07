# Applications::Splunk version 1.0.1

License: MIT
Tags: cfdc, install, splunk, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>, Diego Zamboni <diego.zamboni@cfengine.com>, Nick Anderson <nick@cmdln.org>

## Description
Configure and enable a Splunk forwarder

## Dependencies
CFEngine::dclib

## API
### bundle: install_forwarder
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *installdir* (default: `"/opt/splunkforwarder"`, description: Where will the Splunk forwarder be installed?)

* parameter _string_ *server* (default: none, description: Splunk collecting (remote!) name in server:port format)

* parameter _string_ *password* (default: none, description: Password for the Splunk forwarder)

* parameter _string_ *comment_marker* (default: `"# MANAGED BY CFENGINE"`, description: The comment marker in our Splunk forwarder templates)

* returns _return_ *installed* (default: none, description: none)

* returns _return_ *enabled* (default: none, description: none)

* returns _return_ *configured* (default: none, description: none)

* returns _return_ *restarted* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

