# Libraries::EFL version 1.0

License: GPLv3
Tags: framework, library, enterprise_compatible, enterprise_3_6
Authors: Neil Watson <neilhwatson@evolvethinking.com>

## Description
The bundles contained in this CFEngine library primarily focus on data driven policy. Each such bundle takes CSV or JSON type delimited parameter file as shown in the common bundle efl_c. Website: https://github.com/evolvethinking/evolve_cfengine_freelib Support: http://evolvethinking.com/

## Dependencies
none

## API
### bundle: efl_bundlesequence
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *efl_main_data* (default: none, description: Full path to file containing data used to drive the Evolve Thinking framework bundlesequence.)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

