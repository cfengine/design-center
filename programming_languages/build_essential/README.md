#######################################################
# C and C++ Programming environment
#######################################################

AUTHOR:
 Nakarin Phooripoom <nakarin.phooripoom@cfengine.com>

CATEGORY:
 Programming Languages

LICENSE:
 COPBL

PLATFORMS:
 LINUX (Redhat, CentOS, Debian, Ubuntu, SUSE)

DESCRIPTION:
 This bluprint contains bundles to install packages to be able to compile C/C++ software from source

REQUIREMENTS:
 * CFEngine version 3.x.x
 * Public/Private software repository
 * CFEngine standard library (cfengine_stdlib.cf)

INSTALLATION:
 Save "build_essentail.cf" as "/var/cfengine/masterfiles/blueprints/programming_languages/build_essential.cf" in the policy hub.

SAMPLE USAGE:
 body common control
 {
  bundlesequence => { build_essential("$(state)") };
          inputs => {
                     "blueprints/programming_languages/build_essential.cf", 
                     "cfengine_stdlib.cf",
                    };
 }

 or call the bundle up by methods: promise

 body common control
 {
  bundlesequence => { "main" };
          inputs => {
                     "cfengine_stdlib.cf",
                     "blueprints/programming_languages/build_essential.cf", 
                    };
 }

 bundle agent main
 {
  methods:
   any::
    "build-essential" usebundle => build_essential("$(state)");
 }

 This bundle accepts only 2 values of the $(state) parameter.

 $(state) = "on"
  To install packages

 $(state) = "purge"
  Ton uninstall packages

CHANGES:
 * support SUSE distribution
