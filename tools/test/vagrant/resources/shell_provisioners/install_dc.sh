#!/bin/bash -x

DC=/var/tmp/dc
URL=$1
BRANCH=$2

# If $DC exists, do nothing, assume it's installed already
test -d $DC && exit 0

test -z "$URL" && URL=https://github.com/cfengine/design-center.git
test -z "$BRANCH" && BRANCH=master

apt-get -qq -y install git curl
git clone -q -b $BRANCH $URL $DC

test -d $DC && exit 0

exit 1
