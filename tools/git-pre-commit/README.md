# git-pre-commit - A git hook to test your syntax before letting you commit
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Simple pre-commit hook that runs cf-promises to validate what you are commiting
passes a syntax check.

## REQUIREMENTS
* bash
* Install the commit hook into clone/.git/hooks/pre-commit and make sure its
  executable
* As is the hook expects the root of your clone to be your masterfiles
  location, if you have a different directory that you store your masterfiles
  in the script will need to be adjusted.

## SAMPLE USAGE
    $ git commit -m "Test git pre-commit hook" --author "Nick Anderson <nick@cmdln.org>"
    ###########################################################################
    #                         Syntax Check All Clear                          #
    ###########################################################################
    [master 9e6ddd4] Test git pre-commit hook
     Author: Nick Anderson <nick@cmdln.org>
     1 files changed, 0 insertions(+), 1 deletions(-)
     mode change 100644 => 100755 git-pre-commit


## TODO
* perform test on seperate clone: If you have added a file to your inputs, but
  have not added it to the commit you might pass the test, but the commit would
  still be broken because the included file was not present on another clone.

