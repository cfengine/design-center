#!/bin/bash

DC=$1
URL=$2
BRANCH=$3

# If $DC exists, do nothing, assume it's installed already
test -d $DC && exit 0

test -z "$URL" && URL=https://github.com/cfengine/design-center.git
test -z "$BRANCH" && BRANCH=master

apt-get -qq -y install git
git clone -q -b $BRANCH $URL $DC

test -d $DC && exit 0

exit 1
