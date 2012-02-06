#
#  Copyright (C) CFEngine AS
# 
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License LGPL as published by the
#  Free Software Foundation; version 3.
#   
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  To the extent this program is licensed as part of the Enterprise
#  versions of CFEngine, the applicable Commerical Open Source License
#  (COSL) may apply to this file if you as a licensee so wish it. See
#  included file COSL.txt.
#
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
 This blueprint contains a bundle to install packages to be able to compile C/C++ software from source

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
                     "cfengine_stdlib.cf",
                     "blueprints/programming_languages/build_essential.cf", 
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
    "C/C++" usebundle => build_essential("$(state)");
 }

 This bundle accepts only 2 values of $(state) parameter.

 $(state) = "on"
  To install packages

 $(state) = "purge"
  To uninstall packages

CHANGES:
 * support SUSE distribution
