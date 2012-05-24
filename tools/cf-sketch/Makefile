REPO:=/var/tmp/cfsketch

test-defaults:
	./cf-sketch.pl --deactivate all
	./cf-sketch.pl --install VCS::vcs_mirror --install Monitoring::nagios_plugin_agent
	./cf-sketch.pl --activate VCS::vcs_mirror --params=../../sketches/utilities/vcs_mirror/params/cfengine-copbl.json
	./cf-sketch.pl --generate -v
	(test -f /var/cfengine/inputs/cf-sketch-runfile.cf && cf-agent -I -K -f /var/cfengine/inputs/cf-sketch-runfile.cf) || cf-agent -I -K -f /var/cfengine/masterfiles/cf-sketch-runfile.cf

test: prep
	./cf-sketch.pl --deactivate all
	./cf-sketch.pl --repolist=$(REPO) --install=. -v -f
	./cf-sketch.pl --repolist=$(REPO) --activate Misc::mysketch --params=./params/mysketch.json -v -f
	./cf-sketch.pl --repolist=$(REPO) --generate -v
	cat runme.cf
	cf-agent -I -K -f ./runme.cf

prep:
	/bin/mkdir -p $(REPO)
