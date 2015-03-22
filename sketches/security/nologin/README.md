# Security::nologin version 1.0

License: MIT
Tags: enterprise_compatible, security, sketchify_generated, nologin, enterprise_3_6, cfdc
Authors: Nick Anderson <nick@cmdln.org>

## Description
This sketch provides facilities for restricting non root logins to a host.

## Dependencies
CFEngine::sketch_template

## API
### bundle: etc_nologin (description: If the file /etc/nologin exists and is readable, login(1) will allow access only to root. Other users will be shown the contents of this file and their logins will be refused.)
* bundle option: name = Refuse logins to the system through /etc/nologin

* bundle option: single_use = true

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *state* (default: `"present"`, description: The state of the /etc/nologin file (present|absent).)

* parameter _string_ *content* (default: `"Logins refused by policy."`, description: The content the /etc/nologin file should have.)

### bundle: localuser_nologin (description: The nologin command displays a message that an account is not available and exits non-zero. It is intended as a replacement shell field for accounts that have been disabled.)
* bundle option: single_use = true

* bundle option: name = Refuse login privileges to specific users

* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _list_ *list_of_users* (default: none, description: List of users to be restricted from logging in.)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

