# Utilities::iCal version 1.00

License: MIT
Tags: cfdc, ical, ics, events, todos, holidays, enterprise_compatible, enterprise_3_6
Authors: Ted Zlatanov <tzz@lifelogs.com>
Language: perl

## Description
Parse iCal files for events and TODOs

## Dependencies
CFEngine::sketch_template

## API
### bundle: parse_ical
* bundle option: name = Parse iCal files for events and TODOs

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *calendar_file* (default: `"$(this.promise_dirname)/params/US32Holidays.ics"`, description: Calendar file)

* parameter _boolean_ *define_classes* (default: `true`, description: Define classes for today's events and TODOs?)

* parameter _string_ *days_back* (default: `"0"`, description: Days back from today to examine)

* parameter _string_ *days_forward* (default: `"0"`, description: Days forward from today to examine)

* returns _return_ *events* (default: none, description: none)

* returns _return_ *todo* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

