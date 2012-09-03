# security_limits - Manage /etc/security/limits.conf
## AUTHOR
Nick Anderson <nick@cmdln.org>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux

## DESCRIPTION
Supports selective entry management (addition/removal), or complete file
contents based on the `mgmt_policy` parameter.

Note: the removal of defined limits ignores the limit value. It only looks for
`domain\s+type\s+item`.

## SAMPLE USAGE

    body common control {

        bundlesequence => {"main",};

        inputs => {"../../libraries/copbl/cfengine_stdlib.cf","main.cf",};
    }

    bundle agent main{
    vars:

      oracle_10::
        # This will manage the whole file, only these defined entries allowed
        "limits_domains[oracle][soft][nproc]" string => "2047";
        "limits_domains[oracle][hard][nproc]" string => "16384";
        "limits_domains[oracle][soft][nofile]" string => "1024";
        "limits_domains[oracle][hard][nofile]" string => "65536";
        "limits_mgmt_policy" string => "ensure_present";


    methods:
        "Security Limits" usebundle => security_limits("main.limits_");
    }
