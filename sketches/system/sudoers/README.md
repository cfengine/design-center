# System::Sudoers version 1

License: MIT
Tags: cfdc
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sets defaults and user permissions in the sudoers file

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: ensure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *file_path* (default: `"/etc/sudoers"`, description: none)

* parameter _string_ *visudo_path* (default: `"/usr/sbin/visudo"`, description: none)

* parameter _array_ *defaults* (default: none, description: none)

* parameter _array_ *user_alias* (default: none, description: none)

* parameter _array_ *host_alias* (default: none, description: none)

* parameter _array_ *cmnd_alias* (default: none, description: none)

* parameter _array_ *runas_alias* (default: none, description: none)

* parameter _array_ *user_permissions* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

