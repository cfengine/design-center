# security_limits - Manage /etc/security/limits.conf
## AUTHOR
Nick Anderson <nick@cmdln.org>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux

## DESCRIPTION
Supports selective entry management (addition/removal), or complete file
contents based on the `mgmt_policy` parameter.

Note: the removal of defined limits ignores the limit value. It only looks for
`domain\s+type\s+item`.

## SAMPLE USAGE
See `test.cf` or `params/example.json`
