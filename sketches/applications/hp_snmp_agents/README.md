# Applications::Snmp::hp_snmp_agents - Install and optionally configure hp-snmp-agents

## Authors
Nick Anderson <nick@cmdln.org>

## Description
HP provides snmp agent extensions for monitoring underlying hardware.
The RPMs provided have a "cute" little interactive postinstall process which
will configure snmpd for use with the custom hp snmp agents. This sketch ignors
the post install script (it will just sit there until CFEngine kills off the old
process, which isn't ideal but I am unsure how to bypass that at this time. The
sketch provides the same configuration options for snmpd. You can choose to use
this configuration or do the configuration elsewhere and just let the sketch
install the agents and monitor their status once you have configured snmpd.

## Requirements
The user is expected to make the following hp-snmp-agent packages available for
install via yum if the option pkg_install is enabled. Perhaps checkout
Repository::Yum::Maintain for managing a custom repository.

* hpacucli
* hp-health
* hp-snmp-agents

## Sample Usage

    bundle agent main {
    vars:
      "hpsnmpagents_autoconfig" string => "true";   
      "hpsnmpagents_debug" string => "true";   
      "hpsnmpagents_snmpdconf" string => "/tmp/snmpd.conf";   

      "hpsnmpagents_opt[sci]" string => "Nick Anderson <nick@cmdln.org>";
      "hpsnmpagents_opt[sli]" string => "The MOON";
      "hpsnmpagents_opt[ros]" string => "ReadOnlyCommunityStringOveridesDefault";

    # Valid options
    #  "hpsnmpconfig_opt[rws]"                  string => ""; default private
    #  "hpsnmpconfig_opt[ros]"                  string => ""; default public
    #  "hpsnmpconfig_opt[rwmips]"               string => "";
    #  "hpsnmpconfig_opt[romips]"               string => "";
    #  "hpsnmpconfig_opt[rcs]"                  string => "";
    #  "hpsnmpconfig_opt[tdips]"                string => "";
    #  "hpsnmpconfig_opt[sci]"                  string => "";
    #  "hpsnmpconfig_opt[sli]"                  string => "";
    #  "hpsnmpconfig_debug"                     string => "true|on|yes";
    #  "hpsnmpconfig_autoconfig"                string => "";
    #  "hpsnmpconfig_snmpdconf"                  string => "/etc/snmp/snmpd.conf";

    methods:
      "HP SNMP Agents"
        usebundle => hp_snmp_agents("main.hpsnmpagents_"),
        comment => "Install and configure hp snmp agents";
}

