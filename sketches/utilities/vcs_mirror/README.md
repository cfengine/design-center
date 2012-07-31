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

    # note you can automate the following with cfsketch and the configuration template in params/cfengine-copbl.json

    bundle agent main {
    vars:
      "mirror_copbl_branch" string => "master";
      # see main.cf and test.cf for details on why this needs to be adjusted
      "mirror_copbl_bundle_home" string => "/wherever_you_checked_out_design_center/utilities/vcs_mirror";
      "mirror_copbl_origin" string => "git://github.com/nickanderson/copbl.git";
      "mirror_copbl_path" string => "/tmp/test2/test3/git_mirror";
      "mirror_copbl_runas" string => getenv("USER", 128);
      "mirror_copbl_umask" string => "022";
      "mirror_copbl_vcs" string => "/usr/bin/git";

    methods:
        "any" usebundle => git_mirror("mirror_copbl_");
    }

## TODO
