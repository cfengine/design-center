# cf-cmd - A utility for quickly writing and testing CFEngine files.

## AUTHOR
Diego Zamboni <diego.zamboni@cfengine.com>

## PLATFORM
Any in which Ruby is available.

## DESCRIPTION

I've had to run hundreds of little CFEngine snippets to run tests,
develop examples, verify functionality, or get a solid idea of what
some constructs did. After building the typical "test bundle"
scaffolding in an editor for the hundredth time, I decided to do
something about it. The result is the cf-cmd command. I will let it
speak for itself:

    $ cf-cmd help
    cf-cmd v1.0 - Diego Zamboni <diego@zzamboni.org>
    cf-cmd is a tool that allows you to run small CFEngine snippets quickly,
    by automatically wrapping them around a standard "test" bundle.
    The CFEngine Standard Library is automatically included.
    The following inputs are understood by this tool:
    help     Print this message
    list     Print current policy
    clear    Clear current policy
    go|run   Execute current policy using cf-agent
    type:    Switch to the given promise type
             (classes:, commands:, databases:, environments:, files:, interfaces:,
             methods:, outputs:, packages:, processes:, reports:, services:,
             storage:, vars:)
               The current promise type is shown in the prompt.
    All other lines are added literally to the current promise type.
    Commands can be abbreviated to any part of their name (for example,
    "r" or "ru" for "run").
    You can add lines to any of the standard promise types inside the test
    bundle by switching to the appropriate promise type first.
    The default promise type is "reports:", to make it easier to quickly print
    the value of expressions.
    You can give the inputs also on the command line, they are interpreted
    in exactly the same way (make sure to quote things correctly).
    Examples:
      cf-cmd '"Flavor: $(sys.flavor)";' list run
      cf-cmd '"var1 = $(var1)";' vars: '"var1" string => "test";' l r
      cf-cmd h

You should try out those examples at the end to see what they do. 
The interactive prompt supports editing and completion of all commands
and promise types - press Tab to view available completions.

To install, put the script somewhere in your PATH. If needed, modify the
location of the `cfengine_stdlib.cf` file on your system (by default it
looks for it under `/var/cfengine/inputs/`). You need Ruby installed (I
tested with version 1.9.3).

From Emacs, you can insert an empty test CFEngine file into the
current buffer by pressing `Ctrl-U Meta-! cf-cmd clear list Enter`.

## REQUIREMENTS

- Ruby interpreter

## SAMPLE USAGE

An example interactive session looks like this:

    $ cf-cmd
    reports: > "this is a test";
    reports: > list
    body common control {
       inputs => { "/var/cfengine/inputs/cfengine_stdlib.cf" };
       bundlesequence => { "test" };
    }
    bundle agent test
    {
    reports:
    cfengine::
      "this is a test";
    }
    reports: > run
    -> Running policy with 'cf-agent -KI -f ./test.cf'
    R: this is a test
    reports: > clear
    reports: > l    (abbreviation of "list")
    body common control {
       inputs => { "/var/cfengine/inputs/cfengine_stdlib.cf" };
       bundlesequence => { "test" };
    }
    bundle agent test
    {
    }
    reports: > files: 
    -> Switching to files: promise type.
    files: > "/tmp/test"
    files: >   create => "true",
    files: >   classes => if_repaired("done");
    files: > reports: 
    -> Switching to reports: promise type.
    reports: > done::
    reports: > "Success";
    reports: > l
    body common control {
       inputs => { "/var/cfengine/inputs/cfengine_stdlib.cf" };
       bundlesequence => { "test" };
    }
    bundle agent test
    {
    files:
      "/tmp/test"
        create => "true",
        classes => if_repaired("done");
    reports:
      done::
      "Success";
    }
    reports: > run
    -> Running policy with 'cf-agent -KI -f ./test.cf'
     -> Created file /tmp/test, mode = 600
    R: Success
    reports: > 
