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
# RUBY on RAILS (RUBYGEMS)
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
 This blueprint contains a bundle to RUBY and RUBYGEMS from source then setup rails

REQUIREMENTS:
 * CFEngine version 3.x.x
 * Public/Private software repository
 * CFEngine standard library (cfengine_stdlib.cf)
 * Blueprints: programming_languages/build_essential/build_essential.cf

INSTALLATION:
 Save "prog_ruby_gem_rails.cf" as "/var/cfengine/masterfiles/blueprints/programming_languages/prog_ruby_gem_rails.cf" in the policy hub.

SAMPLE USAGE:
 body common control
 {
  bundlesequence => {
                     build_essential("on"), 
                     prog_ruby_gem_rails("$(ruby)","$(gem)","$(state)"),
                    };
          inputs => {
                     "cfengine_stdlib.cf",
                     "blueprints/programming_languages/build_essential.cf", 
                     "blueprints/programming_languages/prog_ruby_gem_rails.cf", 
                    };
 }

 or call the bundle up by methods: promise

 body common control
 {
  bundlesequence => { "main" };
          inputs => {
                     "cfengine_stdlib.cf",
                     "blueprints/programming_languages/build_essential.cf", 
                     "blueprints/programming_languages/prog_ruby_gem_rails.cf", 
                    };
 }

 bundle agent main
 {
  methods:
   any::
    "C/C++"         usebundle => build_essential("on");
    "RUBY on RAILS" usebundle => prog_ruby_gem_rails("$(ruby)","$(gem)","$(state)");
 }

 This bundle accepts any valid format versions of $(ruby) and $(gem) parameters and only 2 values of $(state) parameter.

  $(ruby)
   Any version of ruby. For instance, "ruby-1.8.7-p357"

  $(gem)
   Any version of gem. For instance, "rubygems-1.8.12"

  $(state) = "on"
   To install RUBY on RAILS

  $(state) = "purge"
   To uninstall RUBY on RAILS

CHANGES:
 * N/A
