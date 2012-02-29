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

Refer to the sketch names paths (paths.cf) for the location of
crontab files.
