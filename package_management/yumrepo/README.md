# Yum Repository Management

## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
Linux

## DESCRIPTION

Create a repository in a given location. Update repository metadata any 
time files are added or removed from the location.

## REQUIREMENTS
* createrepo command is needed to manage repositorys



## SAMPLE USAGE
    bundle agent maintin_repositorys {

        vars:
            "updates_repo" string => "/var/www/html/repo_mirror/updates";
            "custom_repo" string => "/var/www/html/repo_mirror/custom";
            "list_o_repos" slist => { "/var/www/html/repo_mirror/updates1",
                                       "/var/www/html/repo_mirror/updates2",
                                    };

        methods:
            "supplemental_repo" usebundle => yumrepo_maintain_repo("/var/www/html/repo_mirror/supplemental");
            "updates_repo" usebundle => yumrepo_maintain_repo("$(updates_repo)");

            "multiple_repos" 
                usebundle  => yumrepo_maintain_repo("$(list_o_repos)"),
                action     => if_elapsed("60"),
                comment    => "We might not want to constantly search for changed packages";
    }
