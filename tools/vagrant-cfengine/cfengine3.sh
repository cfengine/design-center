POLICYHOST="1.2.3.4"
ENABLE_CLASSES="localDev,drupal7"

#
# Do you have a policyserver you never want to phone home to?
# If so, null route them
#
# sudo netstat -nr
# sudo ip route add blackhole ${POLICYHOST} 
# sudo netstat -nr

#
# Do you need to move group.cf into place for workable tree?
# I do since my code trees arent completely portable.
#
# sudo cp \
# /var/cfengine/masterfiles/inputs/dcsunix/group.cf \
# /var/cfengine/inputs/group.cf
# sudo cp \
# /var/cfengine/masterfiles/inputs/core/failsafe.cf \
# /var/cfengine/inputs/failsafe.cf

#
# Run cf-agent twice, no locks, verbose, with poz-matched classes
#
sudo /var/cfengine/bin/cf-agent -Kv -D ${ENABLE_CLASSES}
sudo /var/cfengine/bin/cf-agent -Kv -D ${ENABLE_CLASSES}
