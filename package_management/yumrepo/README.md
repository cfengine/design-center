# Yum Repository Management

## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
Linux

## DESCRIPTION

* yumrepo_maintain_repo: Create a repository in a given location. Update
  repository metadata any time files are added or removed from the location.

* yumrepo_install_tools: Install tools to work with yum repos.

## REQUIREMENTS
* createrepo command is needed to manage repositorys



## SAMPLE USAGE
    bundle agent maintain_repositorys {

        vars:
            "updates_repo" 
                string  => "/var/www/html/repo_mirror/updates",
                comment => "Updatated packages are mirrored here";

            "custom_repo" 
                string  => "/var/www/html/repo_mirror/custom",
                comment => "We put our custom built packages here";

            "list_o_repos" 
                slist   => { "/var/www/html/repo_mirror/updates1",
                             "/var/www/html/repo_mirror/updates2",
                           },
                comment => "Defining a list of repositories is handy, but its
                            harder document why each repo exists for knowledge
                            management, use your best judgement.";

        methods:
            "install_tools"
                usebundle => yumrepo_install_tools,
                action    => if_elapsed("1440"),
                comment   => "Install tools to work with yum repos,
                              only verrify once a day so we don't waste
                              resources.";

            "supplemental_repo" 
                usebundle => yumrepo_maintain_repo("/var/www/html/repo_mirror/supplemental"),
                comment   => "You can pass in the path directly if you like";

            "updates_repo" 
                usebundle => yumrepo_maintain_repo("$(updates_repo)"),
                comment   => "You can pass in a string variable";

            "multiple_repos" 
                usebundle  => yumrepo_maintain_repo("$(list_o_repos)"),
                action     => if_elapsed("60"),
                comment    => "You can iterate over a list of repositories.
                               You might want to limit how often this happens,
                               constant searching might have a negative 
                               performance impact.";
    }
