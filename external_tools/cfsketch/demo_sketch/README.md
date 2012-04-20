cfsketch: Chinchilla edition (sketch layout and activation RFC)
==========

Welcome to cfsketch.  The flexibility of awk, the power of sed, the appeal of dd... wait that's wrong.

Welcome to cfsketch.  A new world awaits you, citizen... wait that's wrong too, that's phase 2.  Shhh.

Welcome to cfsketch!  This is a "sortoff" tool: "sortoff like CPAN, sortoff like a package manager..."

The goal is to make Design Center sketches easy to install and manage.  So, let's talk about the terminology.

Definitions
----------

cfsketch repository: a directory hierarchy with sketches in it, local or remote.

parameters: data external to cfengine and the sketch, which is used to configure the sketch.  If bundles were functions, parameters would be their... ummm... parameters.  Right.

parameter metadata: a way for the sketch to declare that it uses certain parameters.

sketch entry point and entry bundle: the single way to run a sketch externally.  The entry point is a file; the entry bundle is a bundle in that file that has parameter metadata.  So basically it's a way for cfsketch to know what to run.

sketch installation: this is how sketches are installed in a repository.

sketch activation: this is how installed sketches are configured with a specific set of parameters.

runfile generation: the runfile is a single plan to run all the sketch activations.

Usage
----------

TODO, see Makefile

Sketch Layout
----------

A valid sketch needs just a few things.  First the actual entry point, which is a file full of cfengine goodness.  We'll write one later.

The other really important piece is the sketch.json file.  This file looks like this:

    
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
     "interface": "main.cf"
    }

This may seem like a lot of boilerplate, but in fact it's very simple and most of it can be omitted.  The order of the key-value pairs is not important.

First is the manifest.  That's an array with one key for each file that's part of the sketch.  Each value is a key-value array with keys like "desc" for description and "version" for versioning individual files.

Next comes the metadata.  Simply, it says what the sketch is called (this will be used in variable scoping); the version of the whole sketch, the authors as a list, and the dependencies.

The dependencies can be "cfengine" and "copbl" fof the CFEngine and COPBL versions respectively; "os" for the OS type; or any other sketch with a specific version, if needed.

Finally comes the entry_point and interface.  Those two say to cfsketch "look in main.cf for the main entry bundle and the metadata that defines its interface."

main.cf is your normal every day CFEngine configuration file, except that it 
