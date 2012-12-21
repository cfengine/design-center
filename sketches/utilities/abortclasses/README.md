# abortclasses - 
## AUTHOR
Ben Heilman <bheilman@enova.com>
Nick Anderson <nick@cmdln.org>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux

## DESCRIPTION
Automation is great but sometimes you need to fix problem NOW.

Rather than killing off CFEngine daemons, these bundles will halt cf-agent runs
if a specified file exists. Optionally activate a bundle at the interval of the
timeout specified. The action bundle will be activated during each execution of
the agent that the mtime of the trigger file is older than the specified
timeout. We update the timestamp of the trigger file, when the timeout is
reached.  It is important to note, if CFEngine is unable to update the
timestamp of the trigger file, the action bundle will be activated during each
execution of the agent.
 

The alert and abort bundles should be called as early in the
bundlesequence as possible.

## REQUIREMENTS

Action bundles must take all of the following arguments in order.

    bundle agent timeout_action_bundle(file, years, months, days, hours, minutes, seconds)

## SAMPLE USAGE

First, you must define an class to halt execution:

    body agent control
    {
      ...
      abortclasses => { "cowboy" };
    }

See `test.cf` and `params/example.json` for standalone and JSON-driven usage, respectively.
