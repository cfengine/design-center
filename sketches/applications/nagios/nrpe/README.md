# Applications::Nagios::NRPE version 1

License: MIT
Tags: cfdc, nagios, nrpe
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sketch for configuring Nagios NRPE

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: agent
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *given_conf_file* (default: `"/etc/nagios/nrpe.cfg"`, description: none)

* parameter _string_ *given_local_conf_file* (default: `"/etc/nagios/nrpe_local.cfg"`, description: none)

* parameter _string_ *pidfile* (default: `"/var/run/nagios/nrpe.pid"`, description: none)

* parameter _string_ *server_port* (default: `"5666"`, description: none)

* parameter _string_ *user* (default: `"nagios"`, description: none)

* parameter _string_ *group* (default: `"nagios"`, description: none)

* parameter _string_ *dont_blame_nrpe* (default: `"0"`, description: none)

* parameter _string_ *command_timeout* (default: `"60"`, description: none)

* parameter _string_ *allowed_hosts* (default: none, description: none)

* parameter _array_ *commands* (default: `{}`, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

