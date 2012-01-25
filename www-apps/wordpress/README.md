# Install and configure Wordpress

Original author: Aleksey Tsalolikhin. Enhancements and maintenance: Diego Zamboni.

This Blueprint contains bundles to install and configure a Wordpress installation.

## Installation

Save `wordpress.cf` as `/var/cfengine/masterfiles/blueprints/wordpress.cf` in the policy hub.

## Sample usage

    body common control
    {
      bundlesequence => { wp_install("g.wp_config") };
      inputs => { "cfengine_stdlib.cf", "blueprints/wordpress.cf" };
    }
    
    bundle common g
    {
    vars:
      "wp_config[DB_NAME]"      string => "wordpress";
      "wp_config[DB_USER]"      string => "wordpress";
      "wp_config[DB_PASSWORD]"  string => "lopsa10linux";
      debian::
        "wp_config[_htmlroot]"     string => "/var/www";
      redhat::
        "wp_config[_htmlroot]"     string => "/var/www/html";
      any::
        "wp_config[_wp_dir]"       string => "$(wp_config[_htmlroot])/blog";
    }

Any parameters in `params` that do not start with an underscore (`_`)
will be edited/added to the `wp-config.php` file. You can use this to
modify any other Wordpress parameters you want, for example:

    "wp_config[AUTH_KEY]" string => "foobarbaz";

## Public entry points

- bundle agent wp_install(params)

  Make sure wordpress is installed and configured correctly.
  Mandatory parameters in the "params" array:
  
  - `DB_NAME`
  - `DB_USER`
  - `DB_PASSWORD`
  - `_htmlroot`
  - `_wp_dir` (final wordpress install directory)
  
- bundle agent wp_config(params)

  Make sure wordpress is configured correctly. It must be installed already.
  Mandatory parameters in the "params" array:

  - `_wp_dir` (directory where wordpress is installed)

## Steps followed by `wp_install`

1. Install Infrastructure:
   1. Install httpd and mod_php and PHP MySQL client.
   2. Install MySQL server.
     1. Create WordPress User in MySQL.
     2. Create WordPress Database in MySQL.
   3. Make sure httpd and MySQL servers are running.
2. Install the PHP application (WordPress)
  1. Download tarball with the latest version of WordPress PHP application.
  2. Extract it into the httpd document root where it can be run by the Web server.
  3. Create WordPress config file wp-config.php from wp-config-sample.php that's shipped with WordPress.
  4. Tweak wp-config.php to put in the data needed to establish database connection (db name, db username and password).
