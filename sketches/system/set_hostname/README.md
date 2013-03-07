# set_hostname - Set your machines hostname, or fix it
## AUTHOR
Nick Anderson <nick@cmdln.org>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
darwin
redhat
gentoo
debian

It's easy to add more, please do!

## DESCRIPTION
* cfdc_set_hostname - Make sure the hostname and domainname of the system are set
  properly. Different distributions do things differently, specifically this
  is useful to correct hostname setting on redhat style machines. Contrary to
  official redhat documentation HOSTNAME in /etc/sysconfig/network should not
  be set to the fqdn, it causes the hostname utility to return the fqdn
  instead of the shorthostname when run without arguments.

  For Debian or Ubuntu, the domain name is not stored across reboots
  (patches welcome).

## REQUIREMENTS
* CFEngine Community 3.4.0 or greater
* Standard Library
* Design Center CFEngine::dclib

## SAMPLE USAGE
See `test.cf` and `params/example.json` for standalone and JSON-driven usage, respectively.
