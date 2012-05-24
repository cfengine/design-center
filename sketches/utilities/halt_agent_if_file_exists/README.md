# halt_agent_if_file_exists - 
## AUTHOR
Ben Heilman <bheilman@enova.com>

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

    body common control
    {
      bundlesequence => {
        "halt_agent_if_file_exists_alert(/COWBOY)",
        "halt_agent_if_file_exists_abort(cowboy,/COWBOY)",
        ...,
      };
    }


