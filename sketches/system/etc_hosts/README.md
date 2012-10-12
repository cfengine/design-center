# etc_hosts - Manage your /etc/hosts files
## AUTHOR
Nick Anderson <nick@cmdln.org>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux
darwin
windows

## DESCRIPTION
* cfdc_etc_hosts:configure
    - edit_line based
    - optionally removes any entries not specified except localhost and comments
    - Allows single definition of each entry allowing comments for 
      knowledge management to be attached to each entry.


## REQUIREMENTS
standard library

## SAMPLE USAGE
See `test.cf` and `params/example.json` for standalone and JSON-driven usage, respectively.
