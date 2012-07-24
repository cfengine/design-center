# security_limits - Manage /etc/security/limits.conf
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Supports selective entry managment (addition/removal), or complete file
contents based on defined values.

Note: the removal of defined limits ignores the limit value. It only looks for
`domain\s+type\s+item`.

## SAMPLE USAGE

    # Run with cf-agent -KIf ./test -D debug_complete
    #          cf-agent -KIf ./test -D debug_partial
    #          cf-agent -KIf ./test -D debug_absent
    #
    body common control {

        bundlesequence => {"main",};

        inputs => {"../../libraries/copbl/cfengine_stdlib.cf","main.cf",};
    }

    bundle agent main{
    vars:
      debug_complete::
        # This will manage the whole file, only these defined entries allowed
        "limits_[testuser][soft][nproc]" string => "DEBUG_COMPLETE";
        "limits_[testuser][hard][nproc]" string => "DEBUG_COMPLETE";
        "limits_[testuser][soft][nofile]" string => "DEBUG_COMPLETE";
        "limits_[testuser][hard][nofile]" string => "DEBUG_COMPLETE";
        "limits_mgmt_policy" string => "complete";
        "limits_debug" string => "true";

        
      debug_partial::
        # This will only manage the testuser soft nproc entry
        "limits_[testuser][soft][nproc]" string => "DEBUG_PARTIAL";
        "limits_mgmt_policy" string => "present";
        "limits_debug" string => "true";
    
      debug_absent::
        # This will remove any limit for testuser soft nproc
        "limits_[testuser][soft][nproc]" string => "DEBUG_ABSENT";
        "limits_mgmt_policy" string => "absent";
        "limits_debug" string => "true";

    methods:
      debug_complete|debug_absent|debug_partial::
        "any" usebundle => security_limits("main.limits_");
    }
