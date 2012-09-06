# Hardware::Info - Make policy decisions based on underlying hardware

## Authors
Trondham via cfengineers.org
Nick Anderson <nick@cmdln.org>

## Description
At times you may want to make policy decisions based on underlying hardware
platform. For example install hp-snmp-agents only on hp server hardware.

### Classes raised by this sketch are named as follows
* Manufacturer Class: cfdc_hardware_info_<manufacturer>
* Product Class: cfdc_hardware_info_<manufacturer>_<product_class>
* Example: cfdc_hardware_info_hp
* Example: cfdc_hardware_info_hp_server

Currently detected manufacturers and product classes.
* Dell Servers
* HP Servers
* VMware Virtual Machines
* Lenovo Laptops

## Sample Usage

    bundle agent main {
    # NOTE: This polciy is an example, it wont well unless you have both hp_snmp_agents sketch and actual HP hardware
    vars:
      "hp_snmp_agents_pkg_install" string => "true";

    methods:

      cfdc_hardware_info_hp_server::
        "HP SNMP Agents"
          usebundle => hp_snmp_agents("main.hp_snmp_agents_"),
          comment => "This is used to monitor the hardware health via snmp,
                      it's only useful on HP hardware";

    }

