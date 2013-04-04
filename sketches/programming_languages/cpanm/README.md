# Packages::CPAN::cpanm version 1.1

License: MIT
Tags: cfdc
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Install CPAN packages through App::cpanminus

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: install
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *cpanm_program* (default: `"/usr/local/bin/cpanm"`, description: none)

* parameter _string_ *extra_params* (default: `""`, description: none)

* parameter _list_ *packages* (default: none, description: none)

* returns _return_ *installed* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

