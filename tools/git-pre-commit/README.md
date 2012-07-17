# git-pre-commit - A git hook to test your syntax before letting you commit
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Simple pre-commit hook that runs cf-promises to validate what you are commiting
passes a syntax check.

## REQUIREMENTS
* bash, mktemp
* Install the commit hook into clone/.git/hooks/pre-commit and make sure its
  executable
* As is the hook expects the root of your clone to be your masterfiles
  location, if you have a different directory that you store your masterfiles
  in the script will need to be adjusted.

## SAMPLE USAGE
    $ git commit -m "test commit with broken syntax"
    cf3> /tmp/tmp.5sIqprCoGF/promises.cf:7,8: syntax error, near token 'kdlkjsfs'
    Syntax check on promises.cf FAILED
    Aborting, we dont allow broken commits
