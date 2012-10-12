# cpanm - Install CPAN packages through App::cpanminus

## AUTHORS
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM

Most Debian and RedHat Linux derivatives should work.

## DESCRIPTION

Just provide a list of CPAN modules as shown in `test.cf` or `params/demo.json`

## ## Classes

None.

## ## Variables

* `packages`: a list of packages to be installed
  
* `prefix`: a prefix to be varied with every call of the cpan_install bundle; provided by `cf-sketch` by default when you activate with JSON parameters.
  
* `cpanm_program`: the location of the `cpanm` executable, provided by the CPAN module `App::cpanminus`

* `extra_params`: the extra parameters to pass to `cpanm`
  
## REQUIREMENTS

CFEngine::stdlib (the COPBL)

## SAMPLE USAGE

See `test.cf` and `params/demo.json`
