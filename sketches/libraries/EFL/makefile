update:
	mkdir tmp
	git clone https://github.com/evolvethinking/evolve_cfengine_freelib.git
	cp evolve_cfengine_freelib/masterfiles/lib/3.6/EFL/efl_common.cf .
	cp evolve_cfengine_freelib/masterfiles/lib/3.6/EFL/evolve_freelib.cf .
	cp evolve_cfengine_freelib/masterfiles/lib/3.6/EFL/evolve_freelib.cf .
	rm -rf evolve_cfengine_freelib tmp 
	/var/cfengine/design-center/bin/cf-sketch --make_readme --inputs /var/cfengine/design-center
	/var/cfengine/design-center/bin/cf-sketch --make_cfsketches --inputs /var/cfengine/design-center
	/var/cfengine/design-center/bin/cf-sketch search EFL

