# Networking::NTP::Client version 1

License: MIT
Tags: cfdc, ntp, enterprise_compatible
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sketch for setting NTP client configuration

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: client
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *peers* (default: none, description: none)

* parameter _list_ *servers* (default: none, description: none)

* parameter _list_ *restrictions* (default: none, description: none)

* parameter _string_ *driftfile* (default: `"/var/lib/ntp/drift"`, description: none)

* parameter _string_ *statsdir* (default: `"/var/log/ntpstats"`, description: none)

* parameter _string_ *conffile* (default: `"/etc/ntp.conf"`, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

