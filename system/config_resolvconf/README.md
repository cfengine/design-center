# config_resolvconf - Manage your resolv.conf
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
This bundle will manage your resolv.conf file.
By default it will only set defined options, any manual
additons to the resolvers file will be left un-touched.
There are two special switches
    * _debug will operate on a test file instead of the operating systems resolver
    * _empty will empty the file before setting configuration options, this removes 
      any manual edits on the file and only defined options are set

## REQUIREMENTS

## SAMPLE USAGE
    bundle agent main {

        vars:
            "resolvconf[_debug]" 
                string => "true",
                comment => "If _debug is defined do not operate 
                            on the real resolvers file, but on 
                            a test file like /tmp/resolv.conf";

            "resolvconf[_empty]"
                string => "true",
                comment => "If _empty is defined the file will be
                            emptied before editing, this will remove 
                            any non-defined settings";

            "resolvconf[nameserver]" slist  => { "4.4.8.8", "8.8.8.8" };
            "resolvconf[search]"     slist  => { "example.com", "example.net" };
            "resolvconf[domain]"     slist  => "example.com";
            "resolvconf[sortlist]"   slist  => { "130.155.160.0/255.255.240.0", "130.155.0.0" };
            "resolvconf[options]"    
                slist  => { "ndots:1", "timeout:5", "attempts:2", 
                            "rotate", "no-check-names", "inet6", 
                            "ip6-bytestring", "edns0", "ip6-dotint",
                            "no-ip6-dotint"
                          },
                comment => "These are other options as found in man resolv.conf";


        methods:
            "any" usebundle => cfdc_config_resolvconf("main.resolvconf");
    }

