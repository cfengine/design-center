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
    add-apt-repository http://cfengine.com/pub/apt
    apt-get -qq update
    apt-get -qq -y install cfengine-community
else
    while [ -n "$1" ]; do
        echo Installing requested package $1
        /usr/bin/dpkg -i $1
        shift
    done
fi
