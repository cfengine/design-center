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
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] file (default: "/etc/yum.conf")

* [string] section (default: none)

* [array] config (default: none)

* [return] file (default: none)

* [return] section (default: none)

### ensure_template
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] file (default: none)

* [string] section (default: none)

* [array] template_config (default: none)

* [return] file (default: none)

* [return] section (default: none)

### remove_file
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] remove_file (default: none)

* [return] file (default: none)

### remove_section
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] file (default: "/etc/yum.conf")

* [string] remove_section (default: none)

* [return] section (default: none)

* [return] file (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

