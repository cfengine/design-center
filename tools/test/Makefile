SOURCEDIR:=`pwd`/../../sketches

CFPATH:=$(dirname $(which cf-agent))

ifeq ($(CFPATH),)
  CFPATH:=/var/cfengine/bin
endif

RUNFILE:=~/.cfagent/inputs/standalone-cf-sketch-runfile.cf

ifeq ($(LOGNAME),root)
  RUNFILE:=/var/cfengine/inputs/standalone-cf-sketch-runfile.cf
endif

CFAPI:=`pwd`/../cf-sketch/cf-dc-api.pl `pwd`/../cf-sketch/config.json
CFSKETCH:=`pwd`/../cf-sketch/cf-sketch.pl --installsource=$(SOURCEDIR)/cfsketches --cfpath=$(CFPATH)
CFSKETCH_DA:=rm $(RUNFILE); $(CFSKETCH) --expert --install CFEngine::stdlib --deactivate-all --generate -v
RUNNER:=$(CFPATH)/cf-agent -KI -f $(RUNFILE) -Dverbose -Ddebug -Dtest

api:
	echo 'broken json' | $(CFAPI)
	echo '{ "dc-api-version": "5.0.2"}' | $(CFAPI)
	echo '{ "debug": true, "dc-api-version": "0.0.1"}' | $(CFAPI)
	echo '{ "dc-api-version": "0.0.1", "request": { } }' | $(CFAPI)
	echo '{ "dc-api-version": "0.0.1", "request": {"list": true } }' | $(CFAPI)
	echo '{ "dc-api-version": "0.0.1", "request": {"search": true } }' | $(CFAPI)
	echo '{ "dc-api-version": "0.0.1", "request": {"search": [["name", "contains", "(Cloud|CFEngine)"]] } }' | $(CFAPI)
	echo '{ "dc-api-version": "0.0.1", "request": {"search": [["name", "contains", "Cloud"], ["name", "contains", "CFEngine"]] } }' | $(CFAPI)
	echo '{"dc-api-version": "0.0.1", "request": {"api": [ "Security::SSH" ]} }' | $(CFAPI)
	echo '{"dc-api-version": "0.0.1", "request": {"install": [ "Security::SSH" ], "activate": { "Security::SSH": "../../sketches/networking/ssh/params/simple.json" }} }' | $(CFAPI)

cloud_services:
	$(CFSKETCH_DA) --install Cloud::Services --activate Cloud::Services=$(SOURCEDIR)/cloud/cloud_services/params/demo.json
	$(RUNNER) -Dvcli -Dstart1
	$(RUNNER) -Dec2 -Dstart1
	$(RUNNER) -Dvcli -Dstop1
	$(RUNNER) -Dec2 -Dstop1

db_install:
	$(CFSKETCH_DA) --install Database::Install --activate Database::Install=$(SOURCEDIR)/databases/db_install/params/demo.json
	$(RUNNER) -Dpostgresql -Dpurge
	$(RUNNER) -Dsqlite -Dpurge
	$(RUNNER) -Dmysql -Dpurge
	$(RUNNER) -Dpostgresql
	$(RUNNER) -Dsqlite
	$(RUNNER) -Dmysql
	$(RUNNER) -Dpostgresql -Dserver -Dpurge
	$(RUNNER) -Dsqlite -Dserver -Dpurge
	$(RUNNER) -Dmysql -Dserver -Dpurge
	$(RUNNER) -Dpostgresql -Dserver
	$(RUNNER) -Dsqlite -Dserver
	$(RUNNER) -Dmysql -Dserver
	$(RUNNER) -Dmysql

ssh:
	$(CFSKETCH_DA) --install Security::SSH --activate Security::SSH=$(SOURCEDIR)/networking/ssh/params/simple.json
	$(RUNNER)

aptrepo:
	$(CFSKETCH_DA) --install Repository::apt::Maintain --activate Repository::apt::Maintain=$(SOURCEDIR)/package_management/aptrepo/params/repos.json
	$(RUNNER)

yumclient:
	$(CFSKETCH_DA) --install Repository::Yum::Client --activate Repository::Yum::Client=$(SOURCEDIR)/package_management/yumclient/params/demo.json
	$(RUNNER)

yumrepo:
	$(CFSKETCH_DA) --install Repository::Yum::Maintain --activate Repository::Yum::Maintain=$(SOURCEDIR)/package_management/yumrepo/params/repos.json
	$(RUNNER)

cpanm:
	$(CFSKETCH_DA) --install Packages::CPAN::cpanm --activate Packages::CPAN::cpanm=$(SOURCEDIR)/programming_languages/cpanm/params/demo.json
	$(RUNNER)

limits:
	$(CFSKETCH_DA) --install Security::security_limits --activate Security::security_limits=$(SOURCEDIR)/security/limits/params/example.json
	$(RUNNER)

tcpwrappers:
	$(CFSKETCH_DA) --install Security::tcpwrappers --activate Security::tcpwrappers=$(SOURCEDIR)/security/tcpwrappers/params/params.json
	$(RUNNER)

config_resolver:
	$(CFSKETCH_DA) --install System::config_resolver --activate System::config_resolver=$(SOURCEDIR)/system/config_resolver/params/example.json
	$(RUNNER)

cron:
	$(CFSKETCH_DA) --install System::cron --activate System::cron=$(SOURCEDIR)/system/cron/params/example.json
	$(RUNNER)

etc_hosts:
	$(CFSKETCH_DA) --install System::etc_hosts --activate System::etc_hosts=$(SOURCEDIR)/system/etc_hosts/params/example.json
	$(RUNNER)

set_hostname:
	$(CFSKETCH_DA) --install System::set_hostname --activate System::set_hostname=$(SOURCEDIR)/system/set_hostname/params/example.json
	$(RUNNER)

sysctl:
	$(CFSKETCH_DA) --install System::sysctl --activate System::sysctl=$(SOURCEDIR)/system/sysctl/params/example.json
	$(RUNNER)

tzconfig:
	$(CFSKETCH_DA) --install System::tzconfig --activate System::tzconfig=$(SOURCEDIR)/system/tzconfig/params/example.json
	$(RUNNER)
	$(CFSKETCH_DA) --install System::tzconfig --activate System::tzconfig=$(SOURCEDIR)/system/tzconfig/params/US_Central.json
	$(RUNNER)

abortclasses:
	$(CFSKETCH_DA) --install Utilities::abortclasses --activate Utilities::abortclasses=$(SOURCEDIR)/utilities/abortclasses/params/test_alert_only.json
	$(RUNNER)
	$(CFSKETCH_DA) --install Utilities::abortclasses --activate Utilities::abortclasses=$(SOURCEDIR)/utilities/abortclasses/params/test_no_timeout_action.json
	$(RUNNER)
	$(CFSKETCH_DA) --install Utilities::abortclasses --activate Utilities::abortclasses=$(SOURCEDIR)/utilities/abortclasses/params/test_timeout_action.json
	$(RUNNER)


nagios_plugin_agent:
	@echo NOT IMPLEMENTED

ping_report:
	$(CFSKETCH_DA) --install Utilities::ping_report --activate Utilities::ping_report=$(SOURCEDIR)/utilities/ping_report/params/example.json
	$(RUNNER)

ipverify:
	$(CFSKETCH_DA) --install Utilities::ipverify --activate Utilities::ipverify=$(SOURCEDIR)/utilities/ipverify/params/example.json
	$(RUNNER)

vcs_mirror:
	$(CFSKETCH_DA) --install VCS::vcs_mirror --activate VCS::vcs_mirror=$(SOURCEDIR)/utilities/vcs_mirror/params/cfengine-core-runas-contexts.json
	$(RUNNER)

webserver:
	$(CFSKETCH_DA) --install Webserver::Install --activate Webserver::Install=$(SOURCEDIR)/web_servers/webserver_install/params/apache.json
	$(RUNNER) -Dwebserver

sketch_template:
	$(CFSKETCH_DA) --install CFEngine::sketch_template --activate CFEngine::sketch_template=$(SOURCEDIR)/sketch_template/params/demo.json
	$(RUNNER)

file_integrity:
	$(CFSKETCH_DA) --install Security::file_integrity --activate Security::file_integrity=$(SOURCEDIR)/security/file_integrity/params/pcidss_v2.json
	$(RUNNER)

wordpress:
	@echo NOT IMPLEMENTED
