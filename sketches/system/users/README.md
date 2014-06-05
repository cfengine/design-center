# System::Users version 1.00

License: MIT
Tags: cfdc, users, enterprise_compatible, enterprise_3_6
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Configure users with parameters

## Dependencies
CFEngine::sketch_template

## API
### bundle: ensure_users
* bundle option: name = Ensure the users exist as specified

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _list_ *users* (default: none, description: User names to add (separate by commas))

* parameter _string_ *group* (default: none, description: Primary user group)

* parameter _string_ *homedir* (default: `"/home"`, description: Location of the user's home directory)

* parameter _string_ *shell* (default: `"/bin/bash"`, description: User shell)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

