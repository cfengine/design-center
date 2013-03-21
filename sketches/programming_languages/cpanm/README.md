# Packages::CPAN::cpanm version 1.1

License: MIT
Tags: cfdc
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Install CPAN packages through App::cpanminus

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### install
* _environment_ *runenv* (default: none)

* _metadata_ *metadata* (default: none)

* _string_ *cpanm_program* (default: `"/usr/local/bin/cpanm"`)

* _string_ *extra_params* (default: `""`)

* _list_ *packages* (default: none)

* _return_ *installed* (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

