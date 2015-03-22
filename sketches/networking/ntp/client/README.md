# Networking::NTP::Client version 1

License: MIT
Tags: cfdc, ntp, enterprise_compatible, enterprise_3_6
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sketch for setting NTP client configuration

## Dependencies
CFEngine::sketch_template

## API
### bundle: client
* bundle option: name = Set up a NTP client

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *peers* (default: none, description: List of NTP peers)

* parameter _list_ *servers* (default: none, description: List of NTP servers)

* parameter _list_ *restrictions* (default: none, description: List of NTP restrictions)

* parameter _string_ *driftfile* (default: `"/var/lib/ntp/drift"`, description: Location of drift file)

* parameter _string_ *statsdir* (default: `"/var/log/ntpstats"`, description: Location of stats dir)

* parameter _string_ *conffile* (default: `"/etc/ntp.conf"`, description: Location of NTP configuration file)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

