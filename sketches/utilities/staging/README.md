# Utilities::Staging version 1

License: MIT
Tags: cfdc, stage, directory, rsync
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Stage a directory of content to a target directory.

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## API
### bundle: stage
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *source_dir* (default: none, description: Directory where the content can be found.)

* parameter _string_ *dest_dir* (default: none, description: Directory where the content will be installed.)

* parameter _string_ *owner* (default: none, description: Owner of the dest_dir after staging.)

* parameter _string_ *group* (default: none, description: Owner of the dest_dir after staging.)

* parameter _string_ *dirmode* (default: none, description: Directory mode to install.)

* parameter _string_ *filemode* (default: none, description: File mode to install.)

* parameter _array_ *options* (default: `{"precommand":"/bin/echo precommand","postcommand":"/bin/echo postcommand","excluded":[".cvs",".svn",".subversion",".git",".bzr"]}`, description: Staging options.)

* returns _return_ *staged* (default: none, description: none)

* returns _return_ *directory* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

