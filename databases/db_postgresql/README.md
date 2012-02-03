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
# PostgreSQL (Client/Server)
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
 This blueprint contains a bundle to install PostgreSQL packages and ensure that the process is up and running

REQUIREMENTS:
 * CFEngine version 3.x.x
 * Public/Private software repository
 * CFEngine standard library (cfengine_stdlib.cf)

INSTALLATION:
 Save "db_postgresql.cf" as "/var/cfengine/masterfiles/blueprints/databases/db_postgresql.cf" in the policy hub.

SAMPLE USAGE:
 body common control
 {
  bundlesequence => {
                     db_postgresql("$(type)","$(state)"),
                    };
          inputs => {
                     "cfengine_stdlib.cf",
                     "blueprints/databases/db_postgresql.cf", 
                    };
 }

 or call the bundle up by methods: promise

 body common control
 {
  bundlesequence => { "main" };
          inputs => {
                     "cfengine_stdlib.cf",
                     "blueprints/databases/db_postgresql.cf", 
                    };
 }

 bundle agent main
 {
  methods:
   any::
    "PostgreSQL" usebundle => db_postgresql("$(type)","$(state)");
 }

 This bundle accepts only 2 values of $(type) and $(state) parameters.

 $(type) = "client"
  To select only PostgreSQL client packages to be installed

 $(type) = "server"
  To select both PostgreSQL client and server packages to be installed

 $(state) = "on"
  To install PostgreSQL database

 $(state) = "purge"
  To uninstall PostgreSQL database

CHANGES:
 * N/A
