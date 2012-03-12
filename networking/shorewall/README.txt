Bundles configure and maintain shorewall and shorewall6.

- Requirements

Used paths sketch for global variables.

- For Shorewall

"configure"	usebundle => shorewall_config(
	"@{main.shorewall[interfaces]}",
	"@{main.shorewall[masq]}",
	"@{main.shorewall[policy]}",
	"@{main.shorewall[rules]}",
	"@{main.shorewall[zones]}",
	"on"
	);

"monitor" usebundle => shorewall;

-- bundle agent shorewall_config

Bundle configures shorewall interfaces, masq, policy, rules
and zones files.  Also configures autostart in shorewall.conf
file or defaults/shorewall in Debian.

Fresh iptables rules are cached in safe location.  That
location assumes the global paths sketch is in use for a cache
directory.

-- bundle agent shorewall_check

Bundle compares current iptables rules in the kernel against cached rules from shorewall_config bundle.  Rules are reloaded if there is a difference.


- For Shorewall6

Same functions as shorewall bundles but named shorewall6 and work on ip6tables.

"configure"	usebundle => shorewall6_config(
	"@{main.shorewall6[interfaces]}",
	"@{main.shorewall6[masq]}",
	"@{main.shorewall6[policy]}",
	"@{main.shorewall6[rules]}",
	"@{main.shorewall6[zones]}",
	"on"
	);

"monitor" usebundle => shorewall6_check;


