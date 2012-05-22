## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM

## DESCRIPTION
Have you ever wanted to keep a git clone up to date and clean? Well, I
did and thats what this sketch will help you with. You specify the path
that you want the clone to be, the origin, and the branch to keep the
working tree checked out on.

Every time its executed it will clean the working tree of any untracked
files, reset any modified files in the index or the working tree then
pull updates from its origin and make sure its checked out on the proper
branch.

## REQUIREMENTS

## SAMPLE USAGE

    bundle agent main {
    vars:
        "git[nicks_copbl][path]"     string => "/tmp/test2/test3/git_freshclone";
        "git[nicks_copbl][origin]"   string => "git://github.com/nickanderson/copbl.git";
        "git[nicks_copbl][branch]"   string => "master";

    methods:
        "any" usebundle => git_freshclone("main.git");
    }

## TODO
* Make sure .git/config has proper entries for origin and master 
  (in case someone came along and changed it on us).

* Provide optional container to execute under specified uid/gid
