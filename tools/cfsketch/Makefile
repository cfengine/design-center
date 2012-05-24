REPO:=/var/tmp/cfsketch

test-defaults:
	./cfsketch.pl --deactivate all
	./cfsketch.pl --install VCS::vcs_mirror --install Monitoring::nagios_plugin_agent
	./cfsketch.pl --activate VCS::vcs_mirror --params=../../utilities/vcs_mirror/params/cfengine-copbl.json
	./cfsketch.pl --generate -v
	(test -f /var/cfengine/inputs/cfsketch-runfile.cf && cf-agent -I -K -f /var/cfengine/inputs/cfsketch-runfile.cf) || cf-agent -I -K -f /var/cfengine/masterfiles/cfsketch-runfile.cf

test: prep
	./cfsketch.pl --deactivate all
	./cfsketch.pl --repolist=$(REPO) --install=. -v -f
	./cfsketch.pl --repolist=$(REPO) --activate Misc::mysketch --params=./params/mysketch.json -v -f
	./cfsketch.pl --repolist=$(REPO) --generate -v
	cat runme.cf
	cf-agent -I -K -f ./runme.cf

prep:
	/bin/mkdir -p $(REPO)
