# System::Sudoers version 2.0.2

License: MIT
Tags: cfdc, sudoers
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>, Ben Heilman <bheilman@enova.com>

## Description
Sets defaults and user permissions in the sudoers file

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## API
### bundle: ensure
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *prefix* (default: `"__PREFIX__"`, description: none)

* parameter _string_ *file_path* (default: `"/etc/sudoers"`, description: path to sudoers file to edit)

* parameter _string_ *visudo_path* (default: `"/usr/sbin/visudo"`, description: path to visudo command)

* parameter _array_ *defaults* (default: `[]`, description: none)

* parameter _array_ *user_alias* (default: `[]`, description: none)

* parameter _array_ *host_alias* (default: `[]`, description: none)

* parameter _array_ *cmnd_alias* (default: `[]`, description: none)

* parameter _array_ *runas_alias* (default: `[]`, description: none)

* parameter _array_ *user_specs* (default: `[]`, description: none)

* parameter _array_ *drop_dirs* (default: `[]`, description: Drop directories)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

