# usebundle_if_ip_has_mac - Execute a bundle if reachable ip has known mac 
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Execute a bundle if an ip has a known mac addres
Usefull for performing operatings under certain network conditions.

Consider when networks overlap in multiple enviornments and the agent may
migrate between them like a laptop.

Important note, the bundle to call may not take any paramaters

## REQUIREMENTS

## SAMPLE USAGE

    bundle agent main {
        methods:
            "any" usebundle => cfdc_usebundle_if_ip_has_mac("test", "192.168.1.254", "98:2c:be:27:e8:c9");

    }

    bundle agent test {
        reports:
            cfengine::
                "IP HAD MAC";
    }
