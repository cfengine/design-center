# Webserver::Install - Install and configure a webserver like Apache

## AUTHORS
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM

Linux (Debian and RedHat tested)

## DESCRIPTION

This sketch sets up a web server like Apache with any number of web sites.

## ## Classes

See `test.cf`.

## ## Variables

List your variables here.

Please note that `params/apache.json` has all these parameters in one
place, and it's much more convenient to use JSON data to set these
parameters than manually passing them.

We plan to auto-generate this documentation at some point, so don't go
crazy filling it out.  Better to document in `test.cf` and
`params/apache.json`.

* `myarray`: an array with keys...

## REQUIREMENTS

CFEngine::stdlib (the COPBL)
VCS::vcs_mirror

## SAMPLE USAGE

See `params/apache.json` or `test.cf`.
