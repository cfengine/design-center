# Packages::installed version 1.0.0

License: MIT
Tags: cfdc, packages, enterprise_compatible
Authors: Eystein Stenberg <eystein.maloy.stenberg@cfengine.com>

## Description
Ensure certain packages are removed.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: removed
* bundle option: single_use = true

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *pkgs_removed* (default: none, description: Packages that should not be installed)
