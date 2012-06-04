# Yum Repository Management

## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
Linux

## DESCRIPTION

* yumrepo_maintain: Create a repository in a given list of
  locations. Update repository metadata any time files are added or
  removed from the location.  Optionally, install tools to work with
  yum repos.

To configure 'yumrepo_maintain', use the standard 'cf-sketch' tool and
the supplied parameters, or configure it as follows (using a common
prefix; here we'll just use "yumrepo_maintain_test_" like the
'test.cf' test file uses).

## REQUIREMENTS

* createrepo command is needed to manage repositories, and can be
automatically installed.

* CFEngine::stdlib (the COPBL)

## ## Classes

* $(prefix)install_tools: define this class if you want the
  'createrepo' package installed.

    "yumrepo_maintain_test_install_tools" expression => "any";

## ## Variables

* $(prefix)ifelapsed: a number as a string, determines how long
  between yumrepo_maintain calls.  Optional; defaults to 60.

    "yumrepo_maintain_test_ifelapsed" string => "30";


* $(prefix)repos: an array with keys that are a repository path.  The
  values is an array, whose keys are 'name' or 'perms'.  The 'name'
  key is purely decorative and you could set it to "ay caramba" for
  every path with no ill effect except possibly confusing yourself.
  The 'perms' key must have Yet Another Array as the value; that array
  has keys 'm' for 'mode', 'o' for 'owner', and 'g' for 'group'.  It's
  really simpler to just show it:

    "yumrepo_maintain_test_repos[/var/www/html/repo_mirror/custom][name]" string => "custom";
    "yumrepo_maintain_test_repos[/var/www/html/repo_mirror/custom][perms][g]" string => "root";
    "yumrepo_maintain_test_repos[/var/www/html/repo_mirror/custom][perms][m]" string => "755";
    "yumrepo_maintain_test_repos[/var/www/html/repo_mirror/custom][perms][o]" string => "root";

## SAMPLE USAGE

See test.cf.
