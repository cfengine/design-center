# config_resolver - Manage your resolv.conf
## AUTHOR
Nick Anderson <nick@cmdln.org>
Jean Remond <cfengine@remond.re>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux

## DESCRIPTION
This bundle will manage your resolv.conf file.
By default it will only set defined options, any manual
additons to the resolvers file will be left un-touched.
There are two special switches
    * _debug will operate on a test file (/tmp/resolv.conf) instead of the operating systems resolver
    * if defined_only is "true" or "yes", the sketch will erase the lines which have definitions before setting configuration options, this removes 
      any manual edits on the file and only defined options are set
    * if _empty is "true" or "yes", the file will be emptied before setting configurations options

## REQUIREMENTS

## SAMPLE USAGE

body common control
{
  bundlesequence => { "main", };
  inputs => { "cfengine_stdlib.cf","main.cf" };
}
###########################################################################
    bundle agent main {

        vars:
            "test__bycontext[_debug][file]" 
                string => "/tmp/resolv.conf";
            "test__bycontext[!_debug][file]" 
                string => "/tmp/resolv.conf_etc";

            "test__defined_only" 
                string => "true",
                comment => "Only keep defined entries";

            "test__resolver[nameserver]" slist  => { "4.4.8.8", "8.8.8.8" };
            "test__resolver[search]"     slist  => { "example.com", "example.net" };
            "test__resolver[domain]"     slist  => { "example.com" };
            "test__resolver[sortlist]"   slist  => { "130.155.160.0/255.255.240.0", "130.155.0.0" };
            "test__resolver[options]"    
                slist  => { "ndots:1", "timeout:5", "attempts:2", 
                            "rotate", "no-check-names", "inet6", 
                            "ip6-bytestring", "edns0", "ip6-dotint",
                            "no-ip6-dotint"
                          },
                comment => "These are other options as found in man resolv.conf";


        methods:
            "any" usebundle => cfdc_config_resolver("main.test__");
    }
