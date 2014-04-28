# System::motd version 1.00

License: MIT
Tags: cfdc, enterprise_compatible, enterprise_3_6
Authors: Ben Heilman <bheilman@enova.com>

## Description
Configure the Message of the Day

## Dependencies
CFEngine::sketch_template

## API
### bundle: entry
* bundle option: name = Set up the Message Of The Day

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *motd* (default: none, description: Message of the Day (aka motd))

* parameter _string_ *motd_path* (default: `"/etc/motd"`, description: Location of the primary, often only, MotD file)

* parameter _string_ *prepend_command* (default: `"/bin/uname -snrvm"`, description: Command output to prepend to MotD.  Leave empty to avoid.)

* parameter _string_ *symlink_path* (default: `null`, description: Optional symlink to the motd file)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

