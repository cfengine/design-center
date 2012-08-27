## AUTHOR
Nick Anderson <nick@cmdln.org>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM

## DESCRIPTION
Have you ever wanted to keep a git clone up to date and clean? Well, I
did and thats what this sketch will help you with. You specify the path
that you want the clone to be, the origin, and the branch to keep the
working tree checked out on.

Only Git and Subversion are supported.

Git: every time it's executed it will clean the working tree of any
untracked files, reset any modified files in the index or the working
tree then pull updates from its origin and make sure its checked out
on the proper branch.  It also overwrites the `.git/config` file.

Subversion: just does a `svn cleanup`, `svn up` and `svn revert` every
time after the initial checkout.

The bundle definition is:

    bundle agent vcs_mirror(prefix, class_prefix, vcs, path, origin, branch, runas, umask)

If you choose to call it directly instead of through JSON parameters
(see `params/*.json`), you need to set the following:

* `prefix` is a unique prefix per bundle execution, used to create unique variables.

* `class_prefix` is a unique prefix per bundle execution, used to create unique classes.

* `nowipe` is a context denoting the mirror should not wipe local
  changes.  If you use JSON parameters, this context will come from
  the value you choose and can be `true` or `false` or a string
  context.  If you want to enable this context manually, you have to
  do it like this:
  
    "$(class_prefix)nowipe" expression => "any";

  Where the class_prefix matches the one you passed to the bundle.
  This is to allow multiple invocations of this bundle to have
  different behavior.

* `bundle_home` is the directory where the bundle lives.  You could use `dirname($(this.promise_filename))` for instance.

* `vcs` is either a path ending in `svn` or in `git`.  Anything else is unsupported.

* `path` is the directory where the mirror will be deployed.

* `origin` is the URL or path for the mirror source.

* `branch` is either a Git branch or ignored for Subversion.

* `runas` and `umask` are the user and umask for the mirror command execution.

## REQUIREMENTS

CFEngine::stdlib

## SAMPLE USAGE

See `test.cf`.  Note you can automate the usage with `cf-sketch` and the
configuration template in `params/*.json`

## TODO
