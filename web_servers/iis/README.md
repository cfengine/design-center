#######################################################
# Internet Information Services (IIS) configuration
#######################################################

AUTHOR:
 Eystein Måløy Stenberg <eystein@cfengine.com>

PLATFORM:
 Windows

DESCRIPTION:
 Create IIS sites, and start, stop, delete existing sites.
 Uses the command-line utility appcmd.exe bundled with IIS.
 Does not (yet) support reconfiguring existing sites.

REQUIREMENTS:
 * CFEngine Nova for Windows
 * IIS 7 already installed

SAMPLE USAGE:
 bundle agent service_iis
 {
 vars:
   "start_sites"     slist => { "New site 4" };
   "stop_sites"      slist => { "New site" };
   "delete_sites"    slist => { "New site 5" };

   "site_configs[0][name]" string => "New site 3";
   "site_configs[0][bindings]" string => "http://localhost:8089";
   "site_configs[0][physical_path]" string => "$(docroot)\newsite3";

   "site_configs[1][name]" string => "New site 4";
   "site_configs[1][bindings]" string => "http://localhost:8088";
   "site_configs[1][physical_path]" string => "$(docroot)\newsite4";

 methods:
   "iis"  usebundle => iis("service_iis.site_configs", "@(service_iis.start_sites)", "@(service_iis.stop_sites)", "@(service_iis.delete_sites)");
 }

 Assumes IIS is installed in its default path at inetsrv in the system32 directory.
 If this is not the case, please modify the docroot and appcmd variables.

TODO:
 * Modify incorrectly configured sites (more advanced regex)
 * Support more OS/IIS versions
