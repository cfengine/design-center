# cfdc_configure_apt_sources_list - Manage your deb repositories in /etc/apt/sources.list.d/ files or /etc/apt/sources.list
## AUTHOR
Jean Remond <cfengine@remond.re>

## PLATFORM
linux

## DESCRIPTION
* cfdc_configure_apt_sources_list
    - edit_line based
    - optionally removes any files not specified 


## REQUIREMENTS
standard library

## SAMPLE USAGE
    body common control
    {
          bundlesequence => { "main" };
          inputs => {
                "../../libraries/copbl/cfengine_stdlib.cf",
                "./main.cf",
              };
    }

    bundle agent main
    {
    vars:
       "Repo__apt_repos[contrib-debian-wheezy][distrib]"             string => "debian";
       "Repo__apt_repos[contrib-debian-wheezy][file]"                string => "/tmp/contrib.list";
       "Repo__apt_repos[contrib-debian-wheezy][repo_type][deb]"      string => "true";
       "Repo__apt_repos[contrib-debian-wheezy][repo_type][deb-src]"  string => "false";
       "Repo__apt_repos[contrib-debian-wheezy][repo_url]"            string => "ftp.fr.debian.org";
       "Repo__apt_repos[contrib-debian-wheezy][section]"             string => "contrib";
       "Repo__apt_repos[contrib-debian-wheezy][version_distrib]"     string => "wheezy";
       "Repo__apt_defined_only"                                      string => "no";
       "Repo__apt_multiple_sources_list_files"                       string => "yes";

    methods:
      "Repository::apt::Maintain" usebundle => cfdc_configure_apt_sources_list("main.Repo__apt_");

    }

