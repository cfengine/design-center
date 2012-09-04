# Security::tcpwrappers - Manage /etc/hosts.{allow,deny}
## AUTHOR
Nick Anderson <nick@cmdln.org>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux

## DESCRIPTION
Flexibly manage `/etc/hosts.allow` and `/etc/hosts.deny`.
Support for full file content management with empty_first parameter.
Support for managing rule presence or absense with ensure_present and
ensure_absent file editing policies.

## SAMPLE USAGE

See `test.cf` or `params/params.json` for standalone and data-driven configuration, respectively.
