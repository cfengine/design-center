# tzconfig - Set the system timezone
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
* tzconfig - set the timezone on a system

## REQUIREMENTS


## SAMPLE USAGE

    body common control {

        bundlesequence  => {
                            "main",
                            };

        inputs          => {
                            "cfengine_stdlib.cf",
                            "sketches/tzconfig/tzconfig.cf",
                            };
    }

    bundle agent main {


        vars:
            "tzconfig1_timezone" string => "America/Denverdd";
            "tzconfig2_timezone" string => "America/Chicago";

        methods:
            "timezone" 
                usebundle => tzconfig("main.tzconfig1_"),
                comment => "This timezone is invalid";

            "timezone"
                usebundle => tzconfig("main.tzconfig2_"),
                comment   => "This is a valid timezone";

    }


