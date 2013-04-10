# Repository::Yum::Client version 1.3

License: MIT
Tags: cfdc
Authors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage yum repo client configs in /etc/yum.repos.d

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: ensure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *file* (default: `"/etc/yum.conf"`, description: none)

* parameter _string_ *section* (default: none, description: none)

* parameter _array_ *config* (default: none, description: none)

* returns _return_ *file* (default: none, description: none)

* returns _return_ *section* (default: none, description: none)

### bundle: ensure_template
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *file* (default: none, description: File to ensure. Note that the file will be OVERWRITTEN so you should probably not specify /etc/yum.conf.  If you leave this blank, it will default to /etc/yum.repos.d/SECTION.repo, where SECTION is the 'section' parameter.)

* parameter _string_ *section* (default: none, description: none)

* parameter _array_ *template_config* (default: none, description: none)

* returns _return_ *file* (default: none, description: none)

* returns _return_ *section* (default: none, description: none)

### bundle: remove_file
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *remove_file* (default: none, description: none)

* returns _return_ *file* (default: none, description: none)

### bundle: remove_section
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *file* (default: `"/etc/yum.conf"`, description: none)

* parameter _string_ *remove_section* (default: none, description: none)

* returns _return_ *section* (default: none, description: none)

* returns _return_ *file* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

