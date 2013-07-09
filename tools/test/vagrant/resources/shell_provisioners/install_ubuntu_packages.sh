#!/bin/bash -x

# If /var/cfengine exists, do nothing, assume it's installed already
test -d /var/cfengine && exit 0

cd /tmp

if [ -z "$1" ]; then
    echo Installing Community packages

    wget -q http://cfengine.com/pub/gpg.key
    apt-key add gpg.key
    rm gpg.key

    apt-get -qq update
    apt-get -qq -y install python-software-properties
    apt-get -qq -y install software-properties-common

    if add-apt-repository http://cfengine.com/pub/apt; then
        apt-get -qq update
        apt-get -qq -y install cfengine-community
    else
        echo Could not add the APT repository, falling back to try i386 and amd64 packages
        /usr/bin/dpkg -i /vagrant/resources/packages/cfengine-community_3.5.0-1_i386.deb
        /usr/bin/dpkg -i /vagrant/resources/packages/cfengine-community_3.5.0-1_amd64.deb
    fi
else
    while [ -n "$1" ]; do
        echo Installing requested package $1
        /usr/bin/dpkg -i $1
        shift
    done
fi
