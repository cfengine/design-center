# interface_settings - Manage interface settings
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
* interface_settings_update: Manage an interfaces network configuration

## REQUIREMENTS
* redhat/centos
* cfengine-stdlib

## SAMPLE USAGE
    vars:

            # "nics"              slist   => getindices("sys.ipv4");
            # this would work, you will be limited to taking action and editing
            # interfaces that are already detected. That might be an issue for you
            # if you if your trying to setup any bonds, so its reccomended to manually
            # specify the nics as below 

            "nics"              slist   => { "eth0", "eth1" };

            "eth0[DEVICE]"      string  => "eth0";
            "eth0[BOOTPROTO]"   string  => "none";
            "eth0[ONBOOT]"      string  => "yes";
            "eth0[IPADDR]"      string  => "192.168.35.11";
            "eth0[NETMASK]"     string  => "255.255.255.0";

            "eth1[DEVICE]"      string  => "eth1";
            "eth1[BOOTPROTO]"   string  => "none";
            "eth1[ONBOOT]"      string  => "yes";
            "eth1[IPADDR]"      string  => "172.16.210.65";
            "eth1[NETMASK]"     string  => "255.255.255.192";


    methods:
        "any" usebundle => interface_settings_update("$(nics)", "context.$(nics)");


## TODO
* Add support for other distros

