# Packages::removed version 1.0.0

License: MIT
Tags: cfdc, packages, enterprise_compatible
Authors: Eystein Stenberg <eystein.maloy.stenberg@cfengine.com>

## Description
Ensure certain packages are removed (not installed). The package manager of the OS (e.g. rpm or aptitude) is used to check the status of a package and remove it, if necessary.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: removed
* bundle option: single_use = true

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *pkgs_removed* (default: none, description: Packages that should not be installed)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

