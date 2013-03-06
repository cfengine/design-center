# config_resolver - Manage your resolv.conf
## AUTHOR
Nick Anderson <nick@cmdln.org>
Jean Remond <cfengine@remond.re>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux

## DESCRIPTION

This bundle will manage your resolv.conf file.  It will empty the file before
editing.  In test run environments, it overrides the file name you pass to the
`resolver` bundle to `/tmp/resolv.conf`.

## REQUIREMENTS

## SAMPLE USAGE

See `test.cf` or `params/example.json`.
