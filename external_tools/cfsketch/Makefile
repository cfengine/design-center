REPO:=/var/tmp/cfsketch

test: prep
	./cfsketch.pl --repolist=$(REPO) --install=. -v -f
	./cfsketch.pl --repolist=$(REPO) --activate Misc::mysketch --params=./params/mysketch.json -v
	./cfsketch.pl --repolist=$(REPO) --generate -v
	cat runme.cf
	cf-agent -I -K -f ./runme.cf

prep:
	/bin/mkdir -p $(REPO)
