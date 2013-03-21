# Security::file_integrity version 1

License: MIT
Tags: cfdc, pcidss, pcidss_v2, pcidss_v2_sec_11_5
Authors: Eystein Stenberg <eystein@cfengine.com>

## Description
File hashes will be generated at intervals specified by ifelapsed. On modification, you can update the hashes automatically. In either case, a local report will be generated and transferred to the CFEngine hub (CFEngine Enterprise only). Note that scanning the files requires a lot of disk and CPU cycles, so you should be careful when selecting the amount of files to check and the interval at which it happens (ifelapsed).

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## Parameters
### watch
* [environment] runenv (default: none)

* [metadata] metadata (default: none)

* [list] watch (default: none)

* [string] hash_algorithm (default: "sha256")

* [string] ifelapsed (default: "1440")

* [return] paths (default: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

