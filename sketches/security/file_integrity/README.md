# Security::file_integrity version 1

License: MIT
Tags: cfdc, pcidss, pcidss_v2, pcidss_v2_sec_11_5, enterprise_compatible
Authors: Eystein Stenberg <eystein@cfengine.com>

## Description
File hashes will be generated at intervals specified by ifelapsed. Reports on changes will be part of the FileChanges report table (CFEngine Enterprise only), or agent output in community. Hashing files requires a lot of disk and CPU cycles, so you should be careful when selecting the amount of files to check and the interval at which it happens (ifelapsed).

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: watch
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *watch* (default: none, description: Absolute path to files or directories to watch)

* parameter _string_ *hash_algorithm* (default: `"sha256"`, description: Hash algorithm)

* parameter _string_ *ifelapsed* (default: `"1440"`, description: Time in minutes that should elapse before recheck)

* returns _return_ *paths* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

