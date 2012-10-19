# config_resolver - Manage your resolv.conf
## AUTHOR
Nick Anderson <nick@cmdln.org>
Jean Remond <cfengine@remond.re>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux

## DESCRIPTION
This bundle will manage your resolv.conf file.
By default it will only set defined options, any manual
additons to the resolvers file will be left un-touched.
There are some special contexts (classes):

* `-Dtest` or defining `$(class_prefix)test`will operate on a test
file (`/tmp/resolv.conf` in `test.cf` and in `params/example.json`)
instead of the operating systems resolver.
  
* `-Ddebug` or defining `$(class_prefix)debug`will print extra
debugging information.
  
* if the context `$(class_prefix)defined_only` is defined, the sketch
will erase the lines which have definitions before setting
configuration options, this removes any manual edits on the file and
only defined options are set

* if the context `$(class_prefix)empty_first` is defined, the file
will be emptied before setting configurations options

The rest are variables you pass to the `resolver` bundle:

* `file`: the file to edit (this can be modified by `-Dtest` as explained above)

* `nameserver`, `search`, `options`, `sortlist`, `domain`: slists
(lists of strings) you will see in the resolver configuration
verbatim.

## REQUIREMENTS

## SAMPLE USAGE

See `test.cf` or `params/example.json`.
