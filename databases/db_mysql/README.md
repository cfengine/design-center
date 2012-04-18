
<pre>Copyright (C) CFEngine AS

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License LGPL as published by the
Free Software Foundation; version 3.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.</p>

To the extent this program is licensed as part of the Enterprise
versions of CFEngine, the applicable Commerical Open Source License
(COSL) may apply to this file if you as a licensee so wish it. See
included file COSL.txt.</pre>

<h2>MySQL (Client/Server)</h2>

<h4>AUTHOR:</h4>
 Nakarin Phooripoom <<nakarin.phooripoom@cfengine.com>>

<h4>CATEGORY:</h4>
 Databases

<h4>LICENSE:</h4>
 COPBL

<h4>PLATFORMS:</h4>
 LINUX (Redhat, CentOS, Debian, Ubuntu, SUSE)

<h4>DESCRIPTION:</h4>
 This sketch contains a bundle to install MySQL packages and ensure that the process is up and running

<h4>REQUIREMENTS:</h4>
 * CFEngine version 3.x.x
 * Public/Private software repository
 * CFEngine standard library (`cfengine_stdlib.cf`)

<h4>INSTALLATION:</h4>
 Save `db_mysql.cf` as `/var/cfengine/masterfiles/blueprints/databases/db_mysql.cf` in the policy hub.

<h4>SAMPLE USAGE:</h4>
> <pre>body common control
> {
>  bundlesequence => {
>                     db_mysql("$(type)","$(state)"),
>                    };
>          inputs => {
>                     "cfengine_stdlib.cf",
>                     "design-center/databases/db_mysql.cf", 
>                    };
> }</pre>

 or call the bundle up by `methods:` promise

> <pre>body common control
> {
>  bundlesequence => { "main" };
>          inputs => {
>                     "cfengine_stdlib.cf",
>                     "design-center/databases/db_mysql.cf", 
>                    };
> }</pre>
>
> <pre>bundle agent main
> {
>  methods:
>   any::
>    "MYSQL" usebundle => db_mysql("$(type)","$(state)");
> }</pre>

 This bundle accepts only 2 values of `$(type)` and `$(state)` parameters.

 `$(type) = "client"`
>>To select only MySQL client packages to be installed

 `$(type) = "server"`
>>To select both MySQL client and server packages to be installed

 `$(state) = "on"`
>>To install MYSQL database

 `$(state) = "purge"`
>>To uninstall MYSQL database

<h4>CHANGES:</h4>
 * Terminate running mysql processes when purge selected.

