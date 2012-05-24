# newsketch - A simple bash script to lay down a new CFEngine sketch
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Quickly lay down a new sketch template populated with your defaults.
It sources ~/.newsketch.conf for your default settings, if you don't
have one it just creates one with empty defaults for you to edit to taste.

## REQUIREMENTS
* bash

## SAMPLE USAGE
    $ cat ~/.newsketch.conf
    author="Nick Anderson <nick@cmdln.org>"
    ostype="linux"
    tested=""
    cfengine_version=""

    $ newsketch mycoolsketch

    $ tree mycoolsketch/
    mycoolsketch/
    ├── metadata.txt
    ├── mycoolsketch.cf
    └── README.md

    $ cat mycoolsketch/metadata.txt 
    author:Nick Anderson <nick@cmdln.org>
    ostype:linux
    tested:
    cfengine_version:

    $ cat mycoolsketch/README.md 
    # mycoolsketch - 
    ## AUTHOR
    Nick Anderson <nick@cmdln.org>

    ## PLATFORM
    linux

    ## DESCRIPTION

    ## REQUIREMENTS

    ## SAMPLE USAGE

