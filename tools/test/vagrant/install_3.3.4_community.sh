#!/bin/bash

# If /var/cfengine exists, do nothing, assume it's installed already
test -d /var/cfengine && exit 0

dpkg -i /vagrant/3.3.4/*.deb
