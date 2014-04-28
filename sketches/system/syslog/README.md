# System::syslog version 1

License: MIT
Tags: cfdc, syslog, enterprise_compatible, enterprise_3_6
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>, Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com, Diego Zamboni <diego.zamboni@cfengine.com>

## Description
Manage syslog configuration

## Dependencies
CFEngine::sketch_template

## API
### bundle: set
* bundle option: name = Set up the syslog contents

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *syslog_file* (default: `"/etc/rsyslog.conf"`, description: syslogd/rsyslogd configuration file)

* parameter _boolean_ *empty_first* (default: `false`, description: none)

* parameter _array_ *ensured_kv* (default: none, description: Key-value pairs ensured to be present)

* parameter _array_ *removed_kv* (default: `{"removethisvar":"somevalue"}`, description: Key-value pairs ensured to be removed)

* parameter _list_ *removed_vars* (default: `["nosuchvar"]`, description: Variable names ensured to be present)

* returns _return_ *syslog_file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

