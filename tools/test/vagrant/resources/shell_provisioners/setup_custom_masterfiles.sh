#!/bin/bash -x

ORIGIN=/vagrant/resources/masterfiles.git
REPO=/var/tmp/masterfiles.git

# If $REPO exists, do nothing, assume it's installed already
test -d $REPO && exit 0

cd `dirname $REPO`
sudo -u apache git clone --mirror $ORIGIN $REPO

# exit status = test status
test -d $REPO
