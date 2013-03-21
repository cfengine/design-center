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
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *file* (default: `"/etc/yum.conf"`, description: none)

* _string_ *section* (default: none, description: none)

* _array_ *config* (default: none, description: none)

* _return_ *file* (default: none, description: none)

* _return_ *section* (default: none, description: none)

### ensure_template
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *file* (default: none, description: File to ensure. Note that the file will be OVERWRITTEN so you should probably not specify /etc/yum.conf.  If you leave this blank, it will default to /etc/yum.repos.d/SECTION.repo, where SECTION is the 'section' parameter.)

* _string_ *section* (default: none, description: none)

* _array_ *template_config* (default: none, description: none)

* _return_ *file* (default: none, description: none)

* _return_ *section* (default: none, description: none)

### remove_file
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *remove_file* (default: none, description: none)

* _return_ *file* (default: none, description: none)

### remove_section
* _environment_ *runenv* (default: none, description: none)

* _metadata_ *metadata* (default: none, description: none)

* _string_ *file* (default: `"/etc/yum.conf"`, description: none)

* _string_ *remove_section* (default: none, description: none)

* _return_ *section* (default: none, description: none)

* _return_ *file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

