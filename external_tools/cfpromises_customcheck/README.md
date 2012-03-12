# cfpromises_customcheck.py - a script to test the syntax of your promises files
## AUTHOR
Julien Miotte <miotte.julien@gmail.com>

## PLATFORM
linux

## DESCRIPTION
    This script aims at detecting syntax errors in the cfengine files by
    running cf-promises while defining some classes for each run.

    The promises file should either contain a common ("any::") bundlesequence in
    the common control body or a list of test classes in the following form:
        # TEST_CLASSES:
        # class1
        # class2,class3
        # class4
        # END

    When running the above example, the following commands will be run:
        cf-promises --define class1 -f promises.cf
        cf-promises --define class2,class3 -f promises.cf
        cf-promises --define class4 -f promises.cf

## REQUIREMENTS
* python2.7
* cf-promises

## SAMPLE USAGE
    $ cfpromises_customcheck.py /path/to/PROMISES_FILE
