#!/bin/sh

# Run this script to download the CFEngine package
lynx https://cfengine.com/inside/myspace

echo Now install the package you just downloaded

/bin/sh

echo Checking CFEngine is installed
echo
/var/cfengine/bin/cf-agent -V
