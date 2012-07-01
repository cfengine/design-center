# set_hostname - Set your machines hostname, or fix it
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
* cfdc_set_hostname - Make sure the hostname and domainname of the system are set
  properly. Different distributions do things differently, specifically this
  is useful to correct hostname setting on redhat style machines. Contrary to
  official redhat documentation HOSTNAME in /etc/sysconfig/network should not
  be set to the fqdn, it causes the hostname utility to return the fqdn
  in stead of the shorthostname when run without arguments.

## REQUIREMENTS
* CFEngine Community 3.2.1 or greater
* Standard Library

## SAMPLE USAGE
### set_hostname
    bundle agent main {

        vars:
            "fqdn_hostname" string => "node1";
            "fqdn_domain"   string => "example.com";

        methods:
            "any" usebundle => cfdc_set_hostname("main.fqdn_");

    }
