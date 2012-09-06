# cron - Manage crontab and /etc/cron.d contents
## AUTHOR
Neil H Watson <neil@watson-wilson.ca>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux, darwin, solaris, etc. with crontab/cron.d support

## DESCRIPTION

This `cron` sketch takes the original `cron` sketch written by Neil
Watson and extends it to support `/etc/cron.d` as well.  The latter is
much more pleasant to use than plain crontabs, in our experience.

Furthermore, it moves the configuration of the sketch out of the
CFEngine policy and into the JSON parameters (examples are supplied).

To configure `cron`, use the standard `cf-sketch` tool and the
supplied parameters, or configure it as follows (using a common
prefix; here we'll just use `cron_test_` like the `test.cf` test
file uses).

## ## Classes

* `debug` : show some debugging lines, in order to make sure each value is 
  at the right place.

* `$(class_prefix)nowipe`: don't wipe the existing contents

## ## Variables

* `tasks`: an array definining cron tasks.  The following says: for
  Ubuntu machines, install one jobs as user `tzz` and one as user
  `root` in `/etc/cron.d`, if possible For RedHat machines, install
  one job in user `tzz`'s crontab, again in `/etc/cron.d` if possible.

  Under the key `tasks` you can put any number of task names.  Each
  task name is the key to an array with a `commands` key (an slist of
  commands); a `runas` key (a user name); and a `when` key (a standard
  cron time description).  The following defines task `x`:
  
       "cron_test_cron_path]" string => "/etc/cron.d";
       "cron_test_tasks[x][commands]" slist => {"/home/tzz/bin/tunnels3.pl"};
       "cron_test_tasks[x][runas]" string => "root";
       "cron_test_tasks[x][when]" string => "0 * * * *";

* `cron_path`: the path to the `crontab` binary (must be executable)
  or to the `cron.d` directory (must be a directory) must be
  specified.  If you specify neither an executable nor a directory
  then nothing will happen.

## REQUIREMENTS

CFEngine::stdlib (the COPBL)

## SAMPLE USAGE

See `test.cf` or `params/example.json`.
