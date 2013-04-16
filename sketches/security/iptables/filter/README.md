# security/iptables/filter - 

## AUTHORS
Jon Henrik Bjornstad <jon.henrik.bjornstad@cfengine.com>

## PLATFORM

All Linux platforms that have the iptables-save and iptables-restore command

## DESCRIPTION

This sketch manages simple iptables rules for the filter table. It does so by looking at the rules
currently in use by the kernel and comparing them to what is defined in policy. If the two doesn't match,
CFEngine will load in the correct rules and order overwriting the existing config. This sketch is in nature
different to other iptables management utilities in that we are checking the currently employed rules. 
Many other utilities only manage the start up load rules which doesn't have to be the same as currently
employed at given time.

## ## Classes

Single rules can be activated for contexts/classes

## ## Variables

## REQUIREMENTS

CFEngine::stdlib (the COPBL)

## SAMPLE USAGE

See `test.cf`.
