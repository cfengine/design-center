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

## REQUIREMENTS

CFEngine::stdlib
CFEngine::dclib (the DC standard library)

## SAMPLE USAGE

See `test.cf`.  Note you can automate the usage with `cf-sketch` and the
configuration template in `params/*.json`

## TODO
