#!/bin/bash

DC=$1
EXTRA=$2

# If $DC does not exist, do nothing
test -d $DC || exit 1

apt-get -qq -y install make
cd $DC/tools/test/
export PATH=/var/cfengine/bin:${PATH}
#make splunk
