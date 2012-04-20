REPO:=/var/tmp/cfsketch

test: prep
	./cfsketch.pl --repolist=$(REPO) --install=. -v -f
	./cfsketch.pl --repolist=$(REPO) --activate Misc::mysketch --params=./params/mysketch.json -v
	./cfsketch.pl --repolist=$(REPO) --generate -v
	cat $(REPO)/Misc/mysketch/Misc__mysketch____params_mysketch_json_cf
	cf-agent -I -K -f $(REPO)/Misc/mysketch/Misc__mysketch____params_mysketch_json_cf

prep:
	/bin/mkdir -p $(REPO)
