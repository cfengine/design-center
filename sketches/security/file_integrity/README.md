# Security::file_integrity version 1

License: MIT
Tags: cfdc, pcidss, pcidss_v2, pcidss_v2_sec_11_5
Authors: Eystein Stenberg <eystein@cfengine.com>

## Description
File hashes will be generated at intervals specified by ifelapsed. On modification, you can update the hashes automatically. In either case, a local report will be generated and transferred to the CFEngine hub (CFEngine Enterprise only). Note that scanning the files requires a lot of disk and CPU cycles, so you should be careful when selecting the amount of files to check and the interval at which it happens (ifelapsed).

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: watch
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *watch* (default: none, description: none)

* parameter _string_ *hash_algorithm* (default: `"sha256"`, description: none)

* parameter _string_ *ifelapsed* (default: `"1440"`, description: none)

* returns _return_ *paths* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

