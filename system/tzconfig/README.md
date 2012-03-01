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



        methods:
            "timezone" 
                usebundle => tzconfig("America/Denverdd"),
                comment => "This timezone is invalid";

            "timezone"
                usebundle => tzconfig("America/Chicago"),
                comment   => "This is a valid timezone";

    }


