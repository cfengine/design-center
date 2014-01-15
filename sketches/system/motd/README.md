# System::motd version 1.00

License: MIT
Tags: cfdc
Authors: Ben Heilman <bheilman@enova.com>

## Description
Configure the Message of the Day

## Dependencies
CFEngine::sketch_template

## API
### bundle: entry
* parameter _string_ *motd* (default: none, description: Message of the Day (aka motd))

* parameter _string_ *motd_path* (default: `"/etc/motd"`, description: Location of the primary, often only, MotD file)

* parameter _string_ *prepend_command* (default: `"/bin/uname -snrvm"`, description: Command output to prepend to MotD)

* parameter _string_ *dynamic_path* (default: `null`, description: Location of the dynamic part of the MotD file)

* parameter _string_ *symlink_path* (default: `null`, description: Location of the symlink to the motd file)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

