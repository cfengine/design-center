# etc_hosts - Manage your /etc/hosts files
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
* cfdc_etc_hosts_manage_all_entries
    - edit_line based
    - removes any entries not specified except localhost and comments
    - Allows single definition of each entry allowing comments for 
      knowledge management to be attached to each entry.


## REQUIREMENTS
standard library

## SAMPLE USAGE
    body common control {

    }

       bundlesequence  => {
                           "main",
                           };

       inputs          => {
                           "cfengine_stdlib.cf",
                           "sketches/etc_hosts/etc_hosts.cf",
                           };
    }

    bundle agent main {
       vars:
           "hosts[192.0.2.10]"
               string  => "mailhost.mynet.com ntp02",
               comment => "No one should rely on DNS when resolving the mail server";

           "hosts[192.0.2.11]"
               string => "ntp01.mynet.com ntp02",
               comment => "No one should rely on DNS when resolving local time servers";

           "hosts[192.0.2.12]"
               string => "ntp02.mynet.com ntp02",
               comment => "No one should rely on DNS when resolving local time servers";

           # you can use classes to restrict which nodes would get this setting
           am_db_node::
               "hosts[192.0.2.20]"
                   string  => "clusterscan.mynet.com clusterscan",
                   comment => "DB nodes should get an entry for the db cluster so they arent
                               relying on DNS";


       methods:
           "any" usebundle => cfdc_etc_hosts_manage_all_entries("main.hosts");

    }


