# Hardware::Info - Make policy decisions based on underlying hardware

## Authors
Trondham via cfengineers.org
Nick Anderson <nick@cmdln.org>

## Description
At times you may want to make policy decisions based on underlying hardware
platform. For example install hp-snmp-agents only on hp server hardware.

## Sample Usage

    bundle agent main {
    # NOTE: This polciy is an example, it wont well unless you have both hp_snmp_agents sketch and actual HP hardware
    vars:
      "hp_snmp_agents_pkg_install" string => "true";

    methods:

      hp_hardware_server::
        "HP SNMP Agents"
          usebundle => hp_snmp_agents("main.hp_snmp_agents_"),
          comment => "This is used to monitor the hardware health via snmp,
                      it's only useful on HP hardware";

    }

