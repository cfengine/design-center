# Packages::installed version 1.0.0

License: MIT
Tags: cfdc, packages, enterprise_compatible
Authors: Eystein Stenberg <eystein.maloy.stenberg@cfengine.com>

## Description
Ensure certain packages are installed or not installed. The networked package manager of the OS (e.g. yum or aptitude) is used to perform installations, so the packages to install need to be available in its package repository.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: installed
* bundle option: single_use = true

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *pkgs_add* (default: none, description: Packages that should be installed)

* parameter _list_ *pkgs_delete* (default: none, description: Packages that should not be installed)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

