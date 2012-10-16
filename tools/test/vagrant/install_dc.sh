#!/bin/bash

DC=$1

# If $DC exists, do nothing, assume it's installed already
test -d $DC && exit 0

apt-get -qq -y install git
git clone -q -b 3.4.x https://github.com/tzz/design-center.git $DC

test -d $DC && exit 0

exit 1
