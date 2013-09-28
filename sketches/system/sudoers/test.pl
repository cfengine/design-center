#!/usr/bin/perl

use warnings;
use strict;

use lib "../../libraries/dclib";
use dctest;

my $todo = {
	    "001 metadata check" => qr|___001_System_Sudoers_ensure: System::Sudoers license = MIT|,
	    "002 metadata check" => qr|___002_System_Sudoers_ensure: System::Sudoers license = MIT|,
	    "001 built" => qr|___001_System_Sudoers_ensure: sudoers file /tmp/tmp/sudoers.cfsketch.tmp built|,
	    "002 built" => qr|___002_System_Sudoers_ensure: sudoers file /tmp/tmp/sudoers.d/sample.sudoers.cfsketch.tmp built|,
	    "001 checked" => qr|___001_System_Sudoers_ensure: visudo check passed on /tmp/tmp/sudoers.cfsketch.tmp|,
	    "002 checked" => qr|___002_System_Sudoers_ensure: visudo check passed on /tmp/tmp/sudoers.d/sample.sudoers.cfsketch.tmp|,
	    "001 test mode" => qr|___001_System_Sudoers_ensure: Leaving /tmp/tmp/sudoers.cfsketch.tmp in place in test mode|,
	    "002 test mode" => qr|___002_System_Sudoers_ensure: Leaving /tmp/tmp/sudoers.d/sample.sudoers.cfsketch.tmp in place in test mode|,
	    "drop_dir" => qr|___001_System_Sudoers_ensure: SUDOERS: #includedir /etc/sudoers.d|,
	    "notice" => qr|___002_System_Sudoers_ensure: SUDOERS: # This file is managed by CFEngine, manual edits will be reverted|,
	    "defaults" => qr|___002_System_Sudoers_ensure: SUDOERS: Defaults !authenticate|,
	    "user_alias" => qr|___002_System_Sudoers_ensure: SUDOERS: User_Alias USER_LIST = myuser1, myuser2|,
	    "runas_alias" => qr|___002_System_Sudoers_ensure: SUDOERS: Runas_Alias RUNAS_LIST = root, daemon|,
	    "host_alias" => qr|___002_System_Sudoers_ensure: SUDOERS: Host_Alias HOST_LIST = host1, host2|,
	    "cmnd_alias" => qr|___002_System_Sudoers_ensure: SUDOERS: Cmnd_Alias DUMPS = /usr/sbin/rdump, /usr/sbin/dump, /usr/sbin/restore|,
	    "user_spec_minimal" => qr|___002_System_Sudoers_ensure: SUDOERS: minimal ALL = ALL|,
	    "user_spec_multiple_users" => qr|___002_System_Sudoers_ensure: SUDOERS: user1,user2 ALL = ALL|,
	    "user_spec_multiple_hosts" => qr|___002_System_Sudoers_ensure: SUDOERS: multiple_hosts host1,host2 = ALL|,
	    "user_spec_multiple_commands" => qr|___002_System_Sudoers_ensure: SUDOERS: multiple_commands ALL = /bin/ls, /bin/echo|,
	    "cmnd_spec_runas_users" => qr|___002_System_Sudoers_ensure: SUDOERS: runas_users ALL = \(root,daemon\) ALL|,
	    "cmnd_spec_runas_groups" => qr|___002_System_Sudoers_ensure: SUDOERS: runas_groups ALL = \(: adm,disk\) ALL|,
	    "cmnd_spec_runas_users_and_groups" => qr|___002_System_Sudoers_ensure: SUDOERS: runas_users_and_groups ALL = \(root,daemon : adm,disk\) ALL|,
	    "cmnd_spec_selinux_role" => qr|___002_System_Sudoers_ensure: SUDOERS: runas_selinux_role ALL = ROLE=sysadm_r ALL|,
	    "cmnd_spec_selinux_type" => qr|___002_System_Sudoers_ensure: SUDOERS: runas_selinux_type ALL = TYPE=user_home_t ALL|,
	    "cmnd_spec_tag_specs" => qr|___002_System_Sudoers_ensure: SUDOERS: tag_specs ALL = NOPASSWD: NOSETENV: ALL|,
	   };

my $output = dctest::setup('./test.cf', $todo);

dctest::matchall($output, $todo);
