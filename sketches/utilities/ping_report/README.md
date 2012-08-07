# Utilities::ping_report - Report on pingability of hosts
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
You can use this bundle to report ping connectivity of other hosts.

## SAMPLE USAGE

    body common control {

        bundlesequence => { "main" };

        inputs => { "../../../cfengine_stdlib.cf", "main.cf"};
    }

    bundle agent main {
    vars:
      "test1_count" string => "2";
      "test1_hosts" slist => {"192.168.5.100", "boogie.woogie"};
      "test1_report_success" string => "true";
      "test1_report_failure" string => "on";

    methods:
      "test1" usebundle => ping_report("main.test1_");

    }
