# Packages::installed version 1.0.0

License: MIT
Tags: cfdc, packages, enterprise_compatible, enterprise_3_6
Authors: Eystein Stenberg <eystein.maloy.stenberg@cfengine.com>

## Description
Ensure certain packages are installed. The networked package manager of the OS (e.g. yum or aptitude) is used to perform installations, so the packages need to be available in its package repository.

## Dependencies
CFEngine::sketch_template

## API
### bundle: from_file
* bundle option: name = Install packages listed in an external file

* bundle option: single_use = true

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *file* (default: none, description: Filename with packages, one per line)

* parameter _string_ *state* (default: `"addupdate"`, description: Desired package state)

### bundle: from_list
* bundle option: single_use = true

* bundle option: name = Install specific packages

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *pkgs_add* (default: none, description: Packages that should be installed)

* parameter _string_ *state* (default: `"addupdate"`, description: Desired package state)

### bundle: from_url
* bundle option: single_use = true

* bundle option: name = Install a package from a URL

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *url* (default: none, description: URL for package file)

* parameter _string_ *state* (default: `"addupdate"`, description: Desired package state)

* parameter _string_ *url_retriever* (default: `"/usr/bin/curl -s"`, description: Command to run, will be given the `url` and expected to send the output to STDOUT)

* parameter _string_ *spooldir* (default: `"/var/tmp"`, description: Directory where packages are spooled)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

