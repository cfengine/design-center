
<pre>Copyright 2017 Northern.tech AS

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

<h2>Disable unwanted xinetd services</h2>

<h4>AUTHOR:</h4>
 Nakarin Phooripoom <<nakarin.phooripoom@cfengine.com>>

<h4>CATEGORY:</h4>
 System

<h4>LICENSE:</h4>
 COPBL

<h4>PLATFORMS:</h4>
 LINUX (Redhat, CentOS, Debian, SUSE)

<h4>DESCRIPTION:</h4>
 This sketch contains two bundles to disable unwanted xinetd services with chkconfig command. The list of xinetd services can be changed by directly modify in the policy.

<h4>REQUIREMENTS:</h4>
 * CFEngine version 3.x.x
 * CFEngine standard library (`cfengine_stdlib.cf`)

<h4>INSTALLATION:</h4>
 Save `harden_xinetd.cf` as `/var/cfengine/masterfiles/design-center/system/harden_xinetd.cf` on the policy hub.

<h4>SAMPLE USAGE:</h4>
> <pre>body common control
> {
>  bundlesequence => {
>                     "system_xinetd",
>                    };
>          inputs => {
>                     "cfengine_stdlib.cf",
>                     "design-center/system/harden_xinetd.cf", 
>                    };
> }</pre>

 or call the bundle up by `methods:` promise

> <pre>body common control
> {
>  bundlesequence => { "main" };
>          inputs => {
>                     "cfengine_stdlib.cf",
>                     "design-center/system/harden_xinetd.cf", 
>                    };
> }</pre>
>
> <pre>bundle agent main
> {
>  methods:
>   any::
>    "DISABLE XINETD SERVICES" usebundle => system_xinetd;
> }</pre>

<h4>CHANGES:</h4>
 * N/A

