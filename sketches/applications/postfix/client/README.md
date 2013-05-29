# Applications::Postfix::Client version 1

License: MIT
Tags: cfdc, postfix
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sketch for configuring Postfix Client

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: client
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *given_conf_file* (default: `"/etc/postfix/main.cf"`, description: none)

* parameter _string_ *myhostname* (default: `"$(sys.fqhost)"`, description: none)

* parameter _string_ *mydomain* (default: `"$(sys.domain)"`, description: none)

* parameter _string_ *myorigin* (default: `"$(sys.fqhost)"`, description: none)

* parameter _string_ *relayhost* (default: none, description: none)

* parameter _string_ *mynetworks* (default: `"127.0.0.0/8"`, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

