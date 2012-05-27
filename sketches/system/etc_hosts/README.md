# etc_hosts - Manage your /etc/hosts files
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
* configure_etc_hosts
    - edit_line based
    - optionally removes any entries not specified except localhost and comments
    - Allows single definition of each entry allowing comments for 
      knowledge management to be attached to each entry.


## REQUIREMENTS
standard library

## SAMPLE USAGE
    bundle agent main {
    vars:
        "hosts_entry[192.168.1.254]" string => "gateway.localdomain";
        "hosts_entry[192.168.1.2]"   string => "printer";
        "hosts_defined_only" string => "true";

    methods:
        "etc_hosts"
            usebundle => configure_etc_hosts("main.hosts_");

    }

