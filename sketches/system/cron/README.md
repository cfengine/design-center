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
supplied parameters as a template.

## REQUIREMENTS

CFEngine::stdlib (the COPBL)
CFEngine::dclib (the Design Center stdlib)

## SAMPLE USAGE

See `test.cf` or `params/example.json`.
