# Packages::Debian::single version 1.0.0

License: MIT
Tags: cfdc
Authors: Ben Heilman <bheilman@enova.com>

## Description
Manage Debian Packages one at a time

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: install
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *prefix* (default: `"__PREFIX__"`, description: none)

* parameter _boolean_ *install* (default: none, description: call package installation)

* parameter _string_ *package* (default: none, description: package to install)

* parameter _string_ *version* (default: `null`, description: optional, minimum version of the package required)

* parameter _string_ *release* (default: `null`, description: optional, release to install from, see: apt-get --target-release)

* returns _return_ *package_installed* (default: none, description: none)

### bundle: remove
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *prefix* (default: `"__PREFIX__"`, description: none)

* parameter _boolean_ *remove* (default: none, description: call package removal)

* parameter _string_ *package* (default: none, description: package to remove)

* returns _return_ *package_removed* (default: none, description: none)

### bundle: verify
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *prefix* (default: `"__PREFIX__"`, description: none)

* parameter _boolean_ *verify* (default: none, description: call package verification)

* parameter _string_ *package* (default: none, description: package to verify)

* parameter _string_ *version* (default: `null`, description: optional, minimum version of the package required)

* returns _return_ *package_verified* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

