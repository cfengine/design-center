# usebundle_if_ip_has_mac - Execute a bundle if reachable ip has known mac 
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Execute a bundle if an ip has a known mac addres
Usefull for performing operatings under certain network conditions.

Consider when networks overlap in multiple enviornments and the agent may
migrate between them like a laptop.

Important note, the bundle to call may not take any paramaters

## REQUIREMENTS

## SAMPLE USAGE

    bundle agent main {
    vars:
        "detect_work_ip"          string => "192.168.1.254";
        "detect_work_usebundle"   string => "autocommit_documentation";
        "detect_work_maclist"     slist  => { "62:3c:b4:57:b8:b3" };
 
        "detect_home_ip"          string => "192.168.1.1";
        "detect_home_usebundle"   string => "backup_family_pictures";
        "detect_home_maclist"     slist  => { "98:2c:be:27:e8:c9" };
 
    methods:
        "any" usebundle => usebundle_if_ip_has_mac("main.detect_work_");
        "any" usebundle => usebundle_if_ip_has_mac("main.detect_home_");

    }

    bundle agent backup_family_pictures {
        reports:
            cfengine::
                "I am at home, backup my family pictures to my nas";
    }

    bundle agent autocommit_documentation{
        reports:
            cfengine::
                "I am at work, autocommit my documentation to the repository in case I get hit by a bus on the way home";
    }
