#!/bin/bash

# If /var/cfengine exists, do nothing, assume it's installed already
test -d /var/cfengine && exit 0

cd /tmp
wget -q http://cfengine.com/pub/gpg.key
apt-key add gpg.key
rm gpg.key

apt-get -qq update
apt-get -qq -y install python-software-properties
add-apt-repository http://cfengine.com/pub/apt
apt-get -qq update
apt-get -qq -y install cfengine-community
