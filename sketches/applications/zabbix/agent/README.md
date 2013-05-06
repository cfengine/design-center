# Applications::Zabbix::Agent version 1

License: MIT
Tags: cfdc
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sketch for configuring Zabbix clients

## Dependencies
CFEngine::stdlib

## API
### bundle: applications_zabbix_agent
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *conf_file* (default: `"/etc/zabbix/zabbix_agentd.conf"`, description: none)

* parameter _string_ *server* (default: `"127.0.0.1"`, description: none)

* parameter _string_ *server_port* (default: `"10051"`, description: none)

* parameter _string_ *host_name* (default: `"$(sys.fqhost)"`, description: none)

* parameter _string_ *listen_port* (default: `"10050"`, description: none)

* parameter _string_ *listen_ip* (default: `"0.0.0.0"`, description: none)

* parameter _string_ *start_agents* (default: `"5"`, description: none)

* parameter _string_ *debug_level* (default: `"3"`, description: none)

* parameter _string_ *pid_file* (default: `"/var/run/zabbix/zabbix_agentd.pid"`, description: none)

* parameter _string_ *log_file* (default: `"/var/log/zabbix-agent/zabbix_agentd.log"`, description: none)

* parameter _string_ *timeout* (default: `"3"`, description: none)

* parameter _array_ *user_parameters* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

