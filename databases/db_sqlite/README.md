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
# SQLite
#######################################################

AUTHOR:
 Nakarin Phooripoom <nakarin.phooripoom@cfengine.com>

CATEGORY:
 Databases

LICENSE:
 COPBL

PLATFORMS:
 LINUX (Redhat, CentOS, Debian, Ubuntu, SUSE)

DESCRIPTION:
 This blueprint contains a bundle to install SQLite packages

REQUIREMENTS:
 * CFEngine version 3.x.x
 * Public/Private software repository
 * CFEngine standard library (cfengine_stdlib.cf)

INSTALLATION:
 Save "db_sqlite.cf" as "/var/cfengine/masterfiles/blueprints/databases/db_sqlite.cf" in the policy hub.

SAMPLE USAGE:
 body common control
 {
  bundlesequence => {
                     db_sqlite("$(state)"),
                    };
          inputs => {
                     "cfengine_stdlib.cf",
                     "blueprints/databases/db_sqlite.cf", 
                    };
 }

 or call the bundle up by methods: promise

 body common control
 {
  bundlesequence => { "main" };
          inputs => {
                     "cfengine_stdlib.cf",
                     "blueprints/databases/db_sqlite.cf", 
                    };
 }

 bundle agent main
 {
  methods:
   any::
    "SQLite" usebundle => db_sqlite("$(state)");
 }

 This bundle accepts only 2 values of $(state) parameter.

 $(state) = "on"
  To install SQLite database

 $(state) = "purge"
  To uninstall SQLite database

CHANGES:
 * exclude redhat not to purge SQLite packages as rpm/yum depend on libsqlite3.so.0
