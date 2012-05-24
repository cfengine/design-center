cf-sketch: Hound edition (sketch layout and activation RFC)
==========

Welcome to cf-sketch.  The flexibility of awk, the power of sed, the appeal of dd... wait that's wrong.

Welcome to cf-sketch.  A new world awaits you, citizen... wait that's wrong too, that's phase 2.  Shhh.

Welcome to cf-sketch!  This is a "sortoff" tool: "sortoff like CPAN, sortoff like a package manager..."

The goal is to make Design Center sketches easy to install and manage.  So, let's talk about the terminology.

Definitions
----------

cf-sketch repository: a directory hierarchy with sketches in it, local or remote.

parameters: data external to cfengine and the sketch, which is used to configure the sketch.  If bundles were functions, parameters would be their... ummm... parameters.  Right.

parameter metadata: a way for the sketch to declare that it uses certain parameters.

sketch entry point and entry bundle: the single way to run a sketch externally.  The entry point is a file; the entry bundle is a bundle in that file that has parameter metadata.  So basically it's a way for cf-sketch to know what to run.

sketch installation: this is how sketches are installed in a repository.

sketch activation: this is how installed sketches are configured with a specific set of parameters.

runfile generation: the runfile is a single plan to run all the sketch activations.

Usage
----------

See `Makefile` but realize this is a prototype, so the usage may change.

Most of the options have aliases: -s for --search, -l for --list, -is for --install-source, --it for --install-target, etc. (TODO: list all aliases?)

You can use `/var/tmp`, a nice temporary location, to host our repository, as the `$(REPO)` variable.  But note that `$(REPO)` defaults to `/var/cfengine/inputs/sketches` or `/var/cfengine/masterfiles/sketches`.

For installations, if you don't specify `--install-source`, it defaults to either the local Design Center checkout (if you're running cf-sketch.pl from tools/cf-sketch, this will Just Work) or a single URL: https://raw.github.com/cfengine/design-center/master.

For installations, if you don't specify `--install-target`, it defaults to a local directory just like `$(REPO)` above.

Search for all the *available* sketches in the install source (this can be a regex):

    ./cf-sketch.pl --repolist=$(REPO) -s all
    
Except for the `all` convenience search, this is like `grep WORD ../../sketches/cfsketches` if you're in a Design Center checkout, running from the `tools/cf-sketch` directory.

List all the *installed* sketches in the repolist (this can be a regex):

    ./cf-sketch.pl --repolist=$(REPO) -l all

Install sketch Misc::mysketch from the current Design Center checkout into `$(REPO)`.  Ignore OS and other dependencies with `-f`.  Remember you can use the `-i` and `-it` aliases for `--install` and `--install-target`.

    ./cf-sketch.pl --install-target=$(REPO) --install=Misc::mysketch -v -f

You can stop here and just include the sketch .cf files that were installed in `$(REPO)`, or proceed with parameters and activation.

Activate `Misc::mysketch` (the sketch you just installed from the `demo_sketch` directory) with parameters from `./params/mysketch.json`:

    ./cf-sketch.pl --repolist=$(REPO) --activate Misc::mysketch --params=./params/mysketch.json -v

Admire all the activations, with their data.  Note that the data is brought in *when you activate*.  Also, if you ran things as root, the configuration files will be in `/etc/cf-sketch` instead of `~/.cf-sketch`.

    ./cf-sketch.pl --list-activations

    /bin/cat ~/.cf-sketch/activations.conf

Deactivate a sketch:

    ./cf-sketch.pl --deactivate Misc::mysketch --params=./params/mysketch.json

Deactivate all the activations of a sketch:

    ./cf-sketch.pl --deactivate Misc::mysketch --params=all

Deactivate all the activations of all sketches:

    ./cf-sketch.pl --deactivate all

Remove (uninstall) a sketch:

    ./cf-sketch.pl --remove Misc::mysketch

Generate the runfile for all the activations, currently this will just go into `/var/cfengine/inputs/cf-sketch-runfile.cf` or `/var/cfengine/masterfiles/cf-sketch-runfile.cf` but you can override with the `--runfile` parameter:

    ./cf-sketch.pl --repolist=$(REPO) --generate --runfile ./runme.cf -v

Look at `runme.cf` and you'll see how it sets up activations and policies.
    
    cat runme.cf
    
Run `runme.cf`!  Enjoy!  Use `-v` to see extra debugging information.

    cf-agent -I -K -f ./runme.cf


Sketch Layout
----------

A valid sketch needs just a few things.  First the actual entry point, which is a file full of cfengine goodness.  We'll write one later.

The other really important piece is the `sketch.json` file.  This file looks like this:

    
    { 
     "manifest":
     {
         "main.cf": { "desc": "main file", "version": 1.00 },
     },

     "metadata":
     {
         "name": "Misc::mysketch",
         "version": 3.14,
         "authors": [ "Diego Z", "Ted Z" ],
         "depends": { "copbl": { "version": 105 }, "cfengine": { "version": "3.3.0" }, "os": [ "linux" ] },
     },

     "entry_point": "main.cf",
     "interface": [ "main.cf" ]
    }

This may seem like a lot of boilerplate, but in fact it's very simple and most of it can be omitted.  The order of the key-value pairs is not important.

First is the `manifest`.  That's an array with one key for each file that's part of the sketch.  Each value is a key-value array with keys like _desc_ for description and _version_ for versioning individual files.

Next comes the metadata.  Simply, it says what the sketch is called (this will be used in variable scoping); the version of the whole sketch, the authors as a list, and the dependencies.  **Important about versioning: the version is a string and only a string.  Do not try to interpret it as a number.  The only requirement is that versions should sort lexicographically, that is, "1.2.3 look out llamas" is before 2.3.4 which is before "7.8.9 beta of my soul".**

The dependencies can be _cfengine_ and _copbl_ fof the CFEngine and COPBL versions respectively; _os_ for the OS type; or any other sketch with a specific version, if needed.

Finally comes the `entry_point` and `interface`.  Those two say to cf-sketch "look in `main.cf` for the main entry bundle and the metadata that defines its interface; and to run the bundle you need just `main.cf`"  You can set entry_point to null, in which case cf-sketch knows your sketch doesn't have an entry point (it's just a library like COPBL or the Yale promise library).  The `interface` has to be a valid list of files from the manifest, though.  The `interface` files can include other files, but they are the bare minimum required to run your sketch.  The included "copbl" sketch demonstrates this.

`main.cf` is your normal every day CFEngine configuration file, except that it has to contain two special bundles (this will almost certainly change as cf-sketch integrates more tightly with cfengine metadata).  Here's an example: 

    bundle agent mysketch_main_bundle(prefix)
    {
      reports:
        cfengine_3::
          "myint = $($(prefix)myint); mystr = $($(prefix)mystr); os_special_path = $($(prefix)os_special_path); denied host = $($(prefix)hosts_deny)";
    }

    bundle agent meta_mysketch_main_bundle
    {
      vars:
          "argument[mybool]"          string => "context"; # boolean
          "argument[myint]"           string => "string";
          "argument[mystr]"           string => "string";
          "optional_argument[myopt]"  string => "string";
          "argument[os_special_path]" string => "string";
          "argument[hosts_allow]"     string => "slist";

          "default[os_special_path]"  string => "/no/such/path";
          "default[hosts_allow]"      slist => { "a", "b", "c" };

    }

The parameter metadata is obviously hacked in right now, and you should expect it to change.  So don't complain about it, you in the back.

The important thing is, you define `mysketch_main_bundle` to be the entry bundle, the way to call your sketch.  This is where `sketch.json` and cfengine meet.

Generated file with magic dragons and pixies, AKA runme.cf
----------

`runme.cf` is a generated file that calls all the activated sketches with their parameters.

In addition to the declared parameters, which see above, cf-sketch will also force-feed your sketch some more metadata.  You can then use `$($(prefix)PARAMETER)` to use that metadata.  Specifically:

* `bundle_home`: the directory where the bundle was installed.  You should be able to obtain that with `dirname("$(this.promise_filename)")` but due to bug 718 in the Community Edition of CFEngine, you'll have to use this instead for now.

* `sketch_authors`: a slist of the sketch authors, from `sketch.json`.

* `sketch_depends`: a slist of the sketch dependencies, from `sketch.json`.

* `sketch_manifest`: a slist of the sketch manifest files, from `sketch.json`.

* `sketch_manifest_cf`: a slist of the sketch manifest _.cf_ files, from `sketch.json`.

* `sketch_manifest_docs`: a slist of the sketch manifest _documentation_ files (with `documentation: true`), from `sketch.json`.

* `sketch_manifest_extra`: a slist of the sketch manifest files that are not _.cf_ or _documentation_ files, from `sketch.json`.

* `sketch_name`: the sketch name, from `sketch.json`.

* `sketch_version`: the sketch version, from `sketch.json`.  **Do not use it as a number!**


TODO
----------

Lots of things!!!

* make COPBL included easily

* support generic Git cloning eventually for a repo source

* automatically render documentation files

