# Repository::Yum::Client version 1.3

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage yum repo client configs in /etc/yum.repos.d

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### ensure
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *file* (default: `"/etc/yum.conf"`)

* _string_ *section* (default: none)

* _array_ *config* (default: none)

* _return_ *file* (default: none)

* _return_ *section* (default: none)

### ensure_template
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *file* (default: none)

* _string_ *section* (default: none)

* _array_ *template_config* (default: none)

* _return_ *file* (default: none)

* _return_ *section* (default: none)

### remove_file
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *remove_file* (default: none)

* _return_ *file* (default: none)

### remove_section
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *file* (default: `"/etc/yum.conf"`)

* _string_ *remove_section* (default: none)

* _return_ *section* (default: none)

* _return_ *file* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

