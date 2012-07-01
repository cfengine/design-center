# cf-sketch

cf-sketch is the main tool you will use for setting up sketches from
the Design Center in your own systems. It allows you to search for,
list, install, configure, activate and deactivate sketches.

The following documentation is available in the
[Design Center wiki](https://github.com/cfengine/design-center/wiki): 

- [Getting started with cf-sketch](https://github.com/cfengine/design-center/wiki/Getting-started-with-cf–sketch).
- [cf-sketch manual](https://github.com/cfengine/design-center/wiki/cf–sketch-manual).
- [How to write a new sketch](https://github.com/cfengine/design-center/wiki/How-to-write-a-new-sketch).

If you have any comments or feedback about this tool, please send us
email to <design-center@cfengine.com>, or
[file a new issue](https://github.com/cfengine/design-center/issues)
in this repository.

# TODO
TODO: edit manual and getting started to reflect:

--deactivate-all (same as --deactivate all=1)
--deactivate is a hash now: SKETCH=PFILE or SKETCH=all or all=1
--deactivaten is a list of offsets
--params is a hash now, and applies to all activations, and can only be k=v
--activate is a hash now: SKETCH=PFILE
--save-metarun MFILE.json (saves %options)
--metarun MFILE.json

MFILE.json format: { options => \%options }
where %options is all the options except save-metarun

example:

{
   "options" : {
      "verbose" : 0,
      "dry-run" : 0,
      "configfile" : "/Users/tzz/.cf-sketch/cf-sketch.conf",
      "activate" : {
         "System::cron" : "/Users/tzz/.cfagent/inputs/sketches/System/cron/params/example.json"
      },
      "cfhome" : "/usr/local/bin",
      "generate" : 1,
      "help" : 0,
      "quiet" : 0,
      "runfile" : null,
      "install" : [
         "System::cron"
      ],
      "install-target" : "/Users/tzz/.cfagent/inputs/sketches",
      "repolist" : [
         "/Users/tzz/.cfagent/inputs/sketches"
      ],
      "install-source" : "/Users/tzz/source/design-center/sketches/cfsketches",
      "force" : 1,
      "params" : {
         "a" : "b"
      },
      "make-package" : [],
      "act-file" : "/Users/tzz/.cf-sketch/activations.conf",
      "deactivate-all" : 1,
      "standalone" : 1
   }
}

