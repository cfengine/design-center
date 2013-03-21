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
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [string] cpanm_program (default: "/usr/local/bin/cpanm")

* [string] extra_params (default: "")

* [list] packages (default: none)

* [return] installed (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

