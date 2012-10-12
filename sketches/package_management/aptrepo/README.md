# cfdc_configure_apt_sources_list - Manage your deb repositories in /etc/apt/sources.list.d/ files or /etc/apt/sources.list
## AUTHOR
Jean Remond <cfengine@remond.re>
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM
linux

## DESCRIPTION
* aptrepos
    - edit_line based
    - optionally removes any files not specified 

If you choose to call it directly instead of through JSON parameters
(see `params/*.json`), you need to set the following:

## ## PARAMETERS

The bundle definition is:

    bundle agent aptrepos(class_prefix, repos, apt_file, apt_dir)

* `class_prefix` is a unique prefix per bundle execution, used to create unique classes.

* `repos` is the name of an array with entries for each repo.  See
  `test.cf` or `params/repos.json` for all the keys it needs.

* `apt_file` is the APT file to edit (if `apt_use_file`)

* `apt_dir` is the APT directory where we edit files (if `apt_use_file`)

* `$(class_prefix)wipe` is a context that defines whether the edited
  files will be wiped.  Off by default.

* `$(class_prefix)apt_use_file` is a context that defines whether we
  use `apt_file` or `apt_dir`.  Off by default.

## REQUIREMENTS
standard library

## SAMPLE USAGE
See `test.cf`
