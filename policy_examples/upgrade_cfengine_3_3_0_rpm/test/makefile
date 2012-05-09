
all: meclean 3.2 upgrade

upgrade:
	rsync -av upgrade_cfengine_3_3_0_rpm /var/cfengine/masterfiles/sketches/
	cp promises.cf /var/cfengine/masterfiles/promises.cf
	
3.2:
	rpm -i cfengine-community-3.2.1-1.el5.x86_64.rpm
	cf-agent -B -s 10.7.2.131
	cf-agent -KIB
	cf-agent -KI
	/etc/init.d/cfengine3 start

meclean: 
	rpm -e cfengine-community
	rm -rf /var/cfengine 
	rm -rf /usr/local/sbin/*
