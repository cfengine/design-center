# halt_agent_if_file_exists - 
## AUTHOR
Ben Heilman <bheilman@enova.com>
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Automation is great but sometimes you need to fix problem NOW.  

Rather than killing off CFEngine daemons, these bundles will halt cf-agent runs
 if a specified file exists.

## REQUIREMENTS

## SAMPLE USAGE

First, you must define an class to halt execution:

    body agent control
    {
      ...
      abortclasses => { "cowboy" };
    }

This alert and abort bundle should be called early in the sequence:

    bundle agent main
    {
      vars:
        "cowboy_abort_class"   string => "cowboy";
        "cowboy_trigger_file"  string => "/COWBOY";
        "cowboy_alert"         string => "true"; # True and yes are valid settings
        "cowboy_abort"         string => "yes";  # True and Yes are valid settings

      methods:
        "any" 
            usebundle => cfdc_halt_agent_if_file_exists("main.cowboy_"),
            comment   => "Allow for manual intervention with cowboy mode";

      };
    }


