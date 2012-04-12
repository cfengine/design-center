test:
	./cfsketch.pl --repolist=/var/lib/cfsketch --install=. -v -f
	./cfsketch.pl --repolist=/var/lib/cfsketch --activate Misc::mysketch --ip=./policies/mysketch.json -v
	./cfsketch.pl --repolist=/var/lib/cfsketch --generate -v
	cat /var/lib/cfsketch/Misc/mysketch/Misc__mysketch____policies_mysketch_json_cf
	cf-agent -I -K -f /var/lib/cfsketch/Misc/mysketch/Misc__mysketch____policies_mysketch_json_cf
