REPO:=/var/tmp/cfsketch
PREFIX:=/usr/local
BIN:=$(PREFIX)/bin
LIB:=$(PREFIX)/lib/cf-sketch

test-defaults:
	./cf-sketch.pl --deactivate-all
	./cf-sketch.pl --install VCS::vcs_mirror --install Monitoring::nagios_plugin_agent
	./cf-sketch.pl --activate VCS::vcs_mirror=../../sketches/utilities/vcs_mirror/params/cfengine-copbl.json
	./cf-sketch.pl --generate -v
	(test -f /var/cfengine/inputs/cf-sketch-runfile.cf && cf-agent -I -K -f /var/cfengine/inputs/cf-sketch-runfile.cf) || cf-agent -I -K -f /var/cfengine/masterfiles/cf-sketch-runfile.cf
	./cf-sketch.pl -s all
	./cf-sketch.pl -l all

test: prep
	./cf-sketch.pl --deactivate-all
	./cf-sketch.pl --install-target=$(REPO) --install=Misc::mysketch -v -f
	./cf-sketch.pl --repolist=$(REPO) --activate Misc::mysketch=./params/mysketch.json -v -f
	./cf-sketch.pl --repolist=$(REPO) --generate -v --runfile ./runme.cf
	cat runme.cf
	cf-agent -I -K -f ./runme.cf

install:
	/bin/mkdir -p $(LIB) $(BIN)
	/usr/bin/install ./cf-sketch.pl $(BIN)/cf-sketch
	/usr/bin/install ./cf-dc-api.pl $(BIN)/cf-dc-api
	/bin/cp -a ./perl-lib/* $(LIB)

# Eliminate all signs of cf-sketch from the system. For testing purposes.
clean_system:
	/bin/rm -rf /var/cfengine/inputs/sketches /var/cfengine/masterfiles/sketches /etc/cf-sketch $(HOME)/.cf-sketch $(DST)/cf-sketch
prep:
	/bin/mkdir -p $(REPO)
