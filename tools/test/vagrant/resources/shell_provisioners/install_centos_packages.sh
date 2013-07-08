#!/bin/bash -x

# If /var/cfengine exists, do nothing, assume it's installed already
test -d /var/cfengine && exit 0

cd /tmp

if [ -z "$1" ]; then
    echo Installing Community packages

    wget -q http://cfengine.com/pub/gpg.key
    rpm --import gpg.key
    rm gpg.key

    cat > /etc/yum.repos.d/cfengine-community.repo <<EOHIPPUS
[cfengine-repository]
name=CFEngine
baseurl=http://cfengine.com/pub/yum/
enabled=1
gpgcheck=1
EOHIPPUS

    yum -y install cfengine-community

else
    while [ -n "$1" ]; do
        echo Installing requested package $1
        /usr/bin/rpm -i $1
        shift
    done
fi
