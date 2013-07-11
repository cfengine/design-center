#!/bin/bash -x

DC=/var/tmp/dc
DC_FINAL=/var/cfengine/design-center
URL=$1
BRANCH=$2

# If $DC exists, do nothing, assume it's installed already
test -d $DC && exit 0

test -z "$URL" && URL=https://github.com/cfengine/design-center.git
test -z "$BRANCH" && BRANCH=master

apt-get -qq -y install git curl
yum -y install git curl

# exit status = test status
git clone -q -b $BRANCH $URL $DC && mv $DC_FINAL $DC_FINAL.cfsaved && mv $DC $DC_FINAL && test -d $DC_FINAL
