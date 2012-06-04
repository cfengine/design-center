# db_install - Install MySQL, PostgreSQL, or SQLite

## AUTHORS
Nakarin Phooripoom <nakarin.phooripoom@cfengine.com>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM

Most Debian and RedHat Linux derivatives should work with the supplied
JSON files under `./params`.  For any others, you can define your own
packages to be installed, with the other parameters as explained
below.

## DESCRIPTION

The 'db_install' sketch unites the 'db_sqlite', 'db_postgresql', and
'db_mysql' sketches written by Nakarin Phooripoom
<nakarin.phooripoom@cfengine.com> under one interface.  Furthermore,
it moves the configuration of the sketch out of the CFEngine policy
and into the JSON parameters (examples for MySQL client and server,
PostgreSQL client and server, and SQLite are supplied).

To configure 'db_install', use the standard 'cf-sketch' tool and the
supplied parameters, or configure it as follows (using a common
prefix; here we'll just use "db_install_test_" like the 'test.cf' test
file uses).

## ## Classes

* $(prefix)purge: define this class if you want the database packages
  to be removed

    "db_install_test_purge" expression => "!any";

* $(prefix)server: define this class if you want to install and set up
  a database server.  Otherwise, just the client utilities and
  libraries will be installed.

    "db_install_test_server" expression => "any";

## ## Variables

* $(prefix)contexts_text: just a convenience array normally provided by 'cf-sketch'.  The array contains a text representation of whether the class above is defined (ON) or not (OFF).

    "db_install_test_contexts_text[purge]" string => "OFF";
    "db_install_test_contexts_text[server]" string => "ON";

* $(prefix)db: a string, can be either "mysql" or "postgresql" or "sqlite"

    "db_install_test_db" string => "mysql";


* $(prefix)bycontext: an array with keys that are a context.  This is
  sort of a case statement for CFEngine.  The following says: for
  Ubuntu or Debian machines that are not running Ubuntu 12, define a
  list of base packages, server packages, the process name to match
  when starting or restarting it, and the command to start it.

    "db_install_test_bycontext[!ubuntu_12.(debian|ubuntu)][packages]" slist => {"mysql-client-5.1", "mysql-client-core-5.1", "mysql-common", "libmysqlclient16", "libdbd-mysql-perl", "libdbi-perl", "libnet-daemon-perl", "libplrpc-perl"};
    "db_install_test_bycontext[!ubuntu_12.(debian|ubuntu)][process_match]" string => "/usr/sbin/mysqld.*";
    "db_install_test_bycontext[!ubuntu_12.(debian|ubuntu)][server_packages]" slist => {"mysql-server-5.1", "mysql-server-core-5.1", "libhtml-template-perl"};
    "db_install_test_bycontext[!ubuntu_12.(debian|ubuntu)][start_command]" string => "/etc/init.d/mysql restart";

The important and neat thing about '$(prefix)bycontext' is that it is
extensible by you, the user, without modifying the 'db_install' policy
in 'main.cf'.  As long as your OS is Unix-like, you should be able to
adjust the sketch parameters to Just Work (and if you do, submit your
parameters to the sketch maintainers so we can supply them with the
sketch for everyone's benefit).

## REQUIREMENTS

CFEngine::stdlib (the COPBL)

## SAMPLE USAGE

See test.cf.
