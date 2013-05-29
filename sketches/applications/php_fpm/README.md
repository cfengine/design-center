# Applications::PHP_FPM version 1

License: MIT
Tags: cfdc, php_fpm, php, fpm
Authors: Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## Description
Sketch for installing, configuring, and starting PHP FPM.

## Dependencies
CFEngine::dclib, CFEngine::stdlib

## API
### bundle: server
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *given_conf_file* (default: `"/etc/php5/fpm/php-fpm.conf"`, description: none)

* parameter _string_ *given_pool_dir* (default: `"/etc/php5/fpm/pool.d"`, description: none)

* parameter _string_ *pidfile* (default: `"/var/run/php5-fpm.pid"`, description: none)

* parameter _string_ *pidfile* (default: `"/var/log/php5-fpm.log"`, description: none)

* parameter _array_ *pools* (default: `{}`, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

