Appends provided cronjobs to an existing cronjob file or creates a new one.

Typically used from a main bundle.  Example:

vars:
	"root_cron_jobs" slist => {
		"4	5 * * * * /var/cfengine/bin/cf-execd -F"
	},
	handle => "main_vars_root_cron_jobs";

methods:

	"configure" usebundle => cronjobs("root", @{main.root_cron_jobs}),
		handle => "main_methods_cronjobs";

NOTE: you should have aglobal bundle for crontab location variables.  You can
put them in the bundle but being global means you can recall them for other
bundles.

# definitions for crontabs.

			debian|ubuntu::
				"nhw_crontabs" string => "/var/spool/cron/crontabs";

			redhat::
				"nhw_crontabs" string => "/var/spool/cron";


