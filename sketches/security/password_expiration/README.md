# Security::password_expiration version 1.00

License: MIT
Tags: cfdc
Authors: Diego Zamboni <diego.zamboni@cfengine.com>

## Description
Manage password expiration and age limits

## Dependencies
CFEngine::stdlib

## API
### bundle: password_expiration
* parameter _string_ *pass_max_days* (default: none, description: Maximum password age, in days)

* parameter _string_ *pass_min_days* (default: `"5"`, description: Minimum days between password changes)

* parameter _string_ *pass_warn_age* (default: `"2"`, description: Warning period (in days) before the password expires)

* parameter _string_ *min_uid* (default: `"500"`, description: Minimum UID to consider when making changes to existing users)

* parameter _string_ *skipped_users* (default: `""`, description: Comma-separated list of users to skip)

* parameter _string_ *skipped_uids* (default: `""`, description: Comma-separated list of UIDs to skip)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

