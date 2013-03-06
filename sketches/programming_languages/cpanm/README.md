# cpanm - Install CPAN packages through App::cpanminus

## AUTHORS
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM

Most Debian and RedHat Linux derivatives should work.

## DESCRIPTION

Just provide a list of CPAN modules as shown in `test.cf` or `params/demo.json`

## ## Classes

When the `test` class is defined, the `cpanm_program` is overridden to `echo
cpanm` so you're not actually installing packages.

## ## Variables

* `packages`: a list of packages to be installed
  
* `cpanm_program`: the location of the `cpanm` executable, provided by the CPAN module `App::cpanminus`

* `extra_params`: the extra parameters to pass to `cpanm`
  
## REQUIREMENTS

CFEngine::stdlib (the COPBL)
CFEngine::dclib (the DC standard library)

## SAMPLE USAGE

See `test.cf` and `params/demo.json`
