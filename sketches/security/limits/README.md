# security_limits - Manage /etc/security/limits.conf
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Supports selective entry managment (addition/removal), or complete file
contents based on defined values.

## SAMPLE USAGE

    body common control {

        bundlesequence => {"main",};

        inputs => {"../../../cfengine_stdlib.cf","main.cf",};
    }

    bundle agent main{
    vars:
      "limits_[testuser][soft][nproc]" string => "2047";
      "limits_[testuser][hard][nproc]" string => "16384";
      "limits_[testuser][soft][nofile]" string => "999999";
      "limits_[testuser][hard][nofile]" string => "999999";
      "limits_mgmt_policy" string => "present";
      "limits_debug" string => "true";

      "limits1_[testuser][soft][nproc]" string => "any";
      "limits1_mgmt_policy" string => "absent";
      "limits1_debug" string => "true";


    methods:
      # Ensure specified entries are present
      "any" usebundle => security_limits("main.limits_");
      # Remove specified entrys
      "any" usebundle => security_limits("main.limits1_");
    }
