# Install and configure Wordpress

Authors: Aleksey Tsalolikhin, Diego Zamboni.

This sketch installs and configures a Wordpress installation.

## Usage

Install the sketch using cf-sketch:

    cf-sketch --install WebApps::wordpress_install
    
Look at `params/wordpress.json` for the minimum set of parameters that
you need to configure:

    {
       "wp_dir" : "/var/www/wordpress",
       "wp_params" : {
         "DB_NAME" : "wordpress_db",
         "DB_USER" : "wordpress_user",
         "DB_PASSWORD" : "wordpress_pass"
       },
        "include": [ "wordpress-base.json" ],
    }

The `params/wordpress-base.json` file contains system-specific
parameters that you can also configure. As shipped, this file contains
the parameters for `debian`, `redhat` and `centos` systems.

Once you have configured the parameters file, enable the sketch using
cf-sketch:

    cf-sketch --activate WebApps::wordpress_install --params /var/cfengine/masterfiles/params/wordpress.json 

Finally, you can generate the runfile, either as a standalone file, or
ready to be included in other policy files:

    cf-sketch --generate
    
    cf-sketch --generate --no-standalone

## Steps followed by the sketch

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
