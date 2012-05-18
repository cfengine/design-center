# nagios_plugin_agent - Run nagios plugins and optionally take action
## AUTHOR
Robert Carleton <rbc@rbcarleton.com>
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
This sketch can help you run your nagios plugins. It allows you to execute a
bundle based on the check status of a plugin and raises classes that can be
used for other orchestration.
## REQUIREMENTS
This sketch expects to be able to copy a module from the policy hub.
Be sure to share $(def.masterfiles)/sketches/nagios-plugin-agent/modules/nagios_plugin_wrapper on $(sys.policy_hub)

## SAMPLE USAGE

    bundle agent main {

        vars:
            "check[check_dummy][args]" string => "0 Test ok";

            "check[check_dummy_OK][plugin_name]" string => "check_dummy";
            "check[check_dummy_OK][args]" string => "0 Test ok";
            "check[check_dummy_OK][_usebundle_if_ok]" string => "bundleifok";
            "check[check_dummy_OK][_execution_context]" string => "superdupermop";

            # The execution_context needs to be looked at in depth, doesnt appear to be working.

            #"check[check_dummy_DONTRUN][plugin_name]" string => "check_dummy";
            #"check[check_dummy_DONTRUN][args]" string => "0 Test ok";
            #"check[check_dummy_DONTRUN][_usebundle_if_ok]" string => "bundleifok";
            #"check[check_dummy_DONTRUN][_execution_context]" string => "superdupermop";


            "check[check_dummy_WARN][plugin_name]" string => "check_dummy";
            "check[check_dummy_WARN][args]" string => "1 Test warn";
            "check[check_dummy_WARN][_usebundle_if_warning]" string => "bundleifwarn";

            "check[check_dummy_CRIT][plugin_name]" string => "check_dummy";
            "check[check_dummy_CRIT][args]" string => "2 Test critical";
            "check[check_dummy_CRIT][_usebundle_if_critical]" string => "bundleifcritical";

            "check[check_dummy_UNKNOWN][plugin_name]" string => "check_dummy";
            "check[check_dummy_UNKNOWN][args]" string => "3 Test unknown";
            "check[check_dummy_UNKNOWN][_usebundle_if_critical]" string => "bundleifunknown";

            "check[check_dummy_PROTOERROR][plugin_name]" string => "check_dummy";
            "check[check_dummy_PROTOERROR][args]" string => "4 Test protocal error";
            "check[check_dummy_PROTOERROR][_usebundle_if_protocol_error]" string => "bundleifprotoerror";

        methods:
            "any" usebundle => nagios_plugin_agent("main.check");

    }

    bundle agent bundleifok{
        reports:
            cfengine::
                "THE CHECK WAS OK THIS IS FROM THE CALLED BUNDLE";
    }

    bundle agent bundleifwarn{
        reports:
            cfengine::
                "THE CHECK WAS in WARNING  THIS IS FROM THE CALLED BUNDLE";
    }

    bundle agent bundleifcritical{
        reports:
            cfengine::
                "THE CHECK WAS in CRITICAL  THIS IS FROM THE CALLED BUNDLE";
    }

    bundle agent bundleifunknown{
        reports:
            cfengine::
                "THE CHECK WAS in UNKNOWN  THIS IS FROM THE CALLED BUNDLE";
    }

    bundle agent bundleifprotoerror{
        reports:
            cfengine::
                "THE CHECK WAS in PROTOCAL ERROR  THIS IS FROM THE CALLED BUNDLE";
    }

