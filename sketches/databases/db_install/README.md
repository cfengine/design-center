# db_install - Install MySQL, PostgreSQL, or SQLite

## AUTHORS
Nakarin Phooripoom <nakarin.phooripoom@cfengine.com>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM

Most Debian and RedHat Linux derivatives should work with the supplied
JSON file under `params/demo.json`.  For any others, you can define
your own packages to be installed, with the other parameters as
explained below.

## DESCRIPTION

The `db_install` sketch unites the `db_sqlite`, `db_postgresql`, and
`db_mysql` sketches written by Nakarin Phooripoom
<nakarin.phooripoom@cfengine.com> under one interface.  Furthermore,
it moves the configuration of the sketch out of the CFEngine policy
and into the JSON parameters (examples for MySQL client and server,
PostgreSQL client and server, and SQLite are supplied).

To configure `db_install`, use the standard `cf-sketch` tool and the
supplied parameters, or configure it as follows (using a common
prefix; here we'll just use `dbinstall_` like the `test.cf` test file
uses).

## ## Classes

* `purge`: define this class with `-Dpurge` as shown below if you want
  the database packages to be removed

    "dbinstall_purge" expression => "purge";

* `server`: define this class with `-Dserver` as shown below if you
  want to install and set up a database server.  Otherwise, just the
  client utilities and libraries will be installed.

    "dbinstall_server" expression => "server";

## ## Variables

`params/demo.json` and `test.cf` show how these variables can be set
by simply using `-Dmysql` or `-Dpostgresql` or `-Dsqlite`.

* `db`: a string, can be either `mysql` or `postgresql` or `sqlite`.

    "dbinstall_db" string => "mysql";

* `packages`: a slist of the packages to be always installed

* `server_packages`: a slist of the packages to be installed for
  servers, in addition to `packages`

* `process_match`: the string to match the database server process

* `start_command`: the command to restart the database server

As long as your OS is Unix-like, you should be able to adjust the
sketch parameters to Just Work (and if you do, submit your parameters
to the sketch maintainers so we can supply them with the sketch for
everyone's benefit).

## REQUIREMENTS

CFEngine::stdlib (the COPBL)

## SAMPLE USAGE

See test.cf.
