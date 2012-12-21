# File Integrity checking

##AUTHOR
Eystein Måløy Stenberg <eystein@cfengine.com>

##PLATFORM
Any

##DESCRIPTION
File hashes will be generated at intervals specified by ifelapsed. On modification, you can update the hashes automatically. In either case, a local report will be generated and transferred to the CFEngine hub (CFEngine Enterprise only). Note that scanning the files requires a lot of disk and CPU cycles, so you should be careful when selecting the amount of files to check and the interval at which it happens (ifelapsed).
