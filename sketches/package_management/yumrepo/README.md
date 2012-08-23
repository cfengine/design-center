# Repository::Yum::Maintain - Create and keep Yum repository metadata up to date

## Author
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## Sample Usage

    bundle common cfsketch_g
    {
      classes:
          "yumrepo_maintain_test_install_tools" expression => "any";

    vars:
           "yum_refresh_interval" string => "1";
           "yum_debug" string => "off";
           "yum_verbose" string => "true";
           "yum_repo[custom][path]" string => "/var/www/html/repo_mirror/custom";
           "yum_repo[custom][perms][g]" string => "root";
           "yum_repo[custom][perms][m]" string => "755";
           "yum_repo[custom][perms][o]" string => "root";
           "yum_repo[updates][path]" string => "/var/www/html/repo_mirror/updates";
           "yum_repo[updates][perms][g]" string => "root";
           "yum_repo[updates][perms][m]" string => "755";
           "yum_repo[updates][perms][o]" string => "root";

    }

    bundle agent cfsketch_run
    {
      methods:
          "cfsketch_g" usebundle => "cfsketch_g";
          "test" usebundle => yumrepo_maintain("cfsketch_g.yum_");
    }
