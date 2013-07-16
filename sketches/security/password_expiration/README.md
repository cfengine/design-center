# Security::password_expiration version 1.0

License: MIT
Tags: security, sketchify_generated, cfdc
Authors: Diego Zamboni <diego.zamboni@cfengine.com>

## Description
Manage password expiration and warning periods

## Dependencies
none

## API
### bundle: password_expiration
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *pass_max_days* (default: `"180"`, description: Maximum password age in days)

* parameter _string_ *pass_min_days* (default: `"5"`, description: Minimum password age in days)

* parameter _string_ *pass_warn_age* (default: `"2"`, description: Warning period before password expires, in days)

* parameter _string_ *min_uid* (default: `"500"`, description: Minimum UID to consider when updating existing accounts)

* parameter _string_ *skipped_users* (default: none, description: Comma-separated list of usernames to skip when updating existing accounts)

* parameter _string_ *skipped_uids* (default: none, description: Comma-separated list of UIDs to skip when updating existing accounts)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

