# System::sysctl - Manage sysctl values
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Flexibly manage sysctl values. Provides ability to ensure specific
settings are present or removed, allow only defined values (full file
management) or remove variables no matter what their setting.

## SAMPLE USAGE

    body common control {

        bundlesequence => { "main" };

        inputs => { 
                    "../../libraries/copbl/cfengine_stdlib.cf",
                    "./main.cf",
                  };
    }

    bundle agent main {
    vars:
      "system_memory" string => execresult("/usr/bin/free -m | /usr/bin/awk '/Mem/ {print $2}'", "useshell");
     
      "sysctl_test_file" string => "/tmp/sysctl.conf";
      "sysctl_mgmt_policy" string => "ensure_present";
      "sysctl_empty_first" string => "true";

      all::
        "sysctl_vars[kernel.shmmni]" string => "1024",
          policy => "free";

      # Systems that have a lot of memory should use some of it
      large_memory::
        "sysctl_vars[kernel.shmall]" string => "2097152",
          policy => "free";
        "sysctl_vars[kernel.sem]" string => "250 32000 100 128";
        "sysctl_vars[kernel.shmmax]" string => "2147483648";
        "sysctl_vars[kernel.shmmni]" string => "4096";
        "sysctl_vars[fs.file-max]" string => "65536";
        "sysctl_vars[vm.swappiness]" string => "0";
        "sysctl_vars[vm.vfs_cache_pressure]" string => "50";
        "sysctl_vars[net.ipv4.tcp_tw_reuse]" string => "1";

    classes:
      "large_memory" expression => isgreaterthan("$(system_memory)", "512"),
         comment => "We consider a system has a LOT of memory if its greater
                     than 512M. Afterall 640K ought to be enough for anybody :)";

    methods:
      "sysctl" usebundle => sysctl("main.sysctl_");
    }


