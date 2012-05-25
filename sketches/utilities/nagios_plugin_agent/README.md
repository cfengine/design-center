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

While optional, due to a bug (https://cfengine.com/bugtracker/view.php?id=718) you should supply the bundle_home.
## SAMPLE USAGE
    bundle agent main {
    vars:
        "check_dummy_OK_plugin_name" string => "check_dummy";
        "check_dummy_OK_args" string => "0 Test_OK";
        "check_dummy_OK_usebundle_if_ok" string => "handler_ok";
        "check_dummy_OK_bundle_home" string => "/var/cfengine/inputs/sketches/Monitoring/nagios_plugin_agent";
        "check_dummy_OK_plugin_path" string => "/usr/lib/nagios/plugins/";
        "check_dummy_OK_execution_context" string => "cfengine";
        "check_dummy_OK_if_elapsed" string => "2100";

        "check_dummy_NOTOK_plugin_name" string => "check_dummy";
        "check_dummy_NOTOK_args" string => "1 Test_NOTOK";
        "check_dummy_NOTOK_usebundle_not_ok" string => "handler_not_ok";
        "check_dummy_NOTOK_bundle_home" string => "/var/cfengine/inputs/sketches/Monitoring/nagios_plugin_agent";

    methods:
        "any" usebundle => nagios_plugin_agent("main.check_dummy_OK_");
        "any" usebundle => nagios_plugin_agent("main.check_dummy_NOTOK_");
    }

    bundle agent handler_ok{
    reports:
        cfengine::
            "Check called handler_ok";
    }

    bundle agent handler_not_ok{
    reports:
        cfengine::
            "Check called handler_not_ok";
    }




