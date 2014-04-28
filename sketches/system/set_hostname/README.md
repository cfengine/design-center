# System::set_hostname version 1.05.2

License: MIT
Tags: cfdc, enterprise_compatible, enterprise_3_6
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Set system hostname. Domain name is also set on Mac, Red Hat and and Gentoo derived distributions (but not Debian)

## Dependencies
CFEngine::sketch_template

## API
### bundle: set
* bundle option: name = Set the system hostname

* bundle option: single_use = true

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *hostname* (default: none, description: Host name to set)

* parameter _string_ *domainname* (default: none, description: Domain name to set)

* returns _return_ *hostname* (default: none, description: none)

* returns _return_ *domainname* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

