SOURCEDIR:=`pwd`/../../sketches

CFPATH:=$(dirname $(which cf-agent))

ifeq ($(CFPATH),)
  CFPATH:=/var/cfengine/bin
endif

RUNFILE:=~/.cfagent/inputs/standalone-cf-sketch-runfile.cf

ifeq ($(LOGNAME),root)
  RUNFILE:=/var/cfengine/inputs/standalone-cf-sketch-runfile.cf
endif

ifeq ($(VV),1)
  EXTRA:=--veryverbose
endif

ifeq ($(V),1)
  EXTRA:=--verbose
endif

CFAPI:=`pwd`/../cf-sketch/cf-dc-api.pl `pwd`/../cf-sketch/config.json
CFSKETCH:=`pwd`/../cf-sketch/cf-sketch.pl --expert --installsource=$(SOURCEDIR)/cfsketches --cfpath=$(CFPATH) $(EXTRA) --force
CFSKETCH_DA:=rm $(RUNFILE); $(CFSKETCH) --install CFEngine::stdlib --deactivate-all --generate -v --force --runfile $(RUNFILE)
RUNNER:=$(CFPATH)/cf-agent -KI -f $(RUNFILE)

# api:
# 	echo '{ dc_api_version: "0.0.1", request: {install: { sketch: "Library::Hardware::Info", target: "/home/tzz/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/sketches" } } }' | $(CFAPI)

api2:
	@echo '--- a full test of configuring Security::SSH, CFEngine::sketch_template, and VCS::vcs_mirror --'

	@echo ...define ANYTIME run environment
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "ANYTIME": { activated: "!nosuchclass", test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...define testing run environment
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: true, test: true, verbose: true } } } }' | $(CFAPI)

	@echo ...deactivate all activations
	echo '{ dc_api_version: "0.0.1", request: {deactivate: true } }' | $(CFAPI)

	@echo ...valid request to install Security::SSH, CFEngine::sketch_template, and VCS::vcs_mirror
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "Security::SSH", force: true, target: "/home/tzz/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/sketches" }, { sketch: "CFEngine::sketch_template", force: true, target: "/home/tzz/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/sketches" }, { sketch: "VCS::vcs_mirror", force: true, target: "/home/tzz/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/sketches" } ] } }' | $(CFAPI)

	@echo ...define Security::SSH simple_ssh and CFEngine::sketch_template simple_sketch parameters
	echo '{ dc_api_version: "0.0.1", request: {define: { "simple_sketch": { "CFEngine::sketch_template": { myboolean: true, myip: "10.0.1.0", mylist: [ 1, 2, 3 ], myarray: { a: 1, b: 3, c: 3 } } }, "simple_ssh": { "Security::SSH": { params: { Protocol : "2", X11Forwarding : "yes", PermitRootLogin : "yes" } } } } } }' | $(CFAPI)
	@echo define VCS::vcs_mirror parameters
	echo '{ dc_api_version: "0.0.1", request: {define: { "vcs_base": { "VCS::vcs_mirror": { options: { parent_dir: { owner: { "function": "getenv", "args": ["LOGNAME", "128"] }, group: { "function": "getenv", "args": ["LOGNAME", "128"] }, perms: "755", ensure: true }, nowipe: true, vcs: { runas: { "function": "getenv", "args": ["LOGNAME", "128"] }, umask: "000" } } } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "git_mirror_core": { "VCS::vcs_mirror": { vcs: "/usr/bin/git", path: "/tmp/q/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git" } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "svn_mirror_thrift": { "VCS::vcs_mirror": { vcs: "/usr/bin/svn", path: "/tmp/thrift-perl-lib", branch: "", origin: "http://svn.apache.org/repos/asf/thrift/attic/trunk/lib/perl", options: { parent_dir: { ensure: false } }  } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "git_invalid": { "VCS::vcs_mirror": { path: "/tmp/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git", options: { umask: "000" }, vcs: "/no/such/versioning_system" } } } } }' | $(CFAPI)

	@echo ...activate Security::SSH with ANYTIME run environment and simple_ssh parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { target: "/home/tzz/.cfagent/inputs/sketches", environment: "ANYTIME", params: [ "simple_ssh" ] } } } }' | $(CFAPI)
	@echo ...activate CFEngine::sketch_template with testing run environment and simple_sketch parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "CFEngine::sketch_template": { target: "/home/tzz/.cfagent/inputs/sketches", environment: "testing", params: [ "simple_sketch" ] } } } }' | $(CFAPI)
	@echo ...activate VCS::vcs_mirror with testing run environment and vcs_base+git_mirror_core and vcs_base+svn_mirror_thrift parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "VCS::vcs_mirror": { target: "/home/tzz/.cfagent/inputs/sketches", environment: "testing", params: [ "vcs_base", "git_mirror_core" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "VCS::vcs_mirror": { target: "/home/tzz/.cfagent/inputs/sketches", environment: "testing", params: [ "vcs_base", "svn_mirror_thrift" ] } } } }' | $(CFAPI)
	@echo ...activate VCS::vcs_mirror with testing run environment and git_invalid parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "VCS::vcs_mirror": { target: "/home/tzz/.cfagent/inputs/sketches", environment: "testing", params: [ "git_invalid" ] } } } }' | $(CFAPI)

	@echo ...list installed
	echo '{ dc_api_version: "0.0.1", request: {list: true } }' | $(CFAPI)
	@echo ...generate the runfile
	echo '{ dc_api_version: "0.0.1", request: {regenerate: { } } }' | $(CFAPI)

api_basics:
	@echo ...invalid data
	echo 'broken json' | $(CFAPI)
	@echo ...invalid API version
	echo '{ dc_api_version: "5.0.2" }' | $(CFAPI)
	@echo ...debug mode
	echo '{ dc_api_version: "0.0.1", debug: true }' | $(CFAPI)
	@echo ...empty request
	echo '{ dc_api_version: "0.0.1", request: { } }' | $(CFAPI)
	@echo ...list installed
	echo '{ dc_api_version: "0.0.1", request: {list: true } }' | $(CFAPI)
	@echo ...list installed matching Cloud or CFEngine
	echo '{ dc_api_version: "0.0.1", request: {list: [["name", "matches", "(Cloud|CFEngine|Security)"]] } }' | $(CFAPI)
	@echo ...search all available
	echo '{ dc_api_version: "0.0.1", request: {search: true } }' | $(CFAPI)
	@echo ...search available matching cloud or cfengine via regex
	echo '{ dc_api_version: "0.0.1", request: {search: [["name", "matches", "(Cloud|CFEngine)"]] } }' | $(CFAPI)
	@echo ...search available matching cloud or cfengine via data alternation
	echo '{ dc_api_version: "0.0.1", request: {search: [["name", "matches", "Cloud"], ["name", "matches", "CFEngine"]] } }' | $(CFAPI)
	@echo ...get CFEngine::sketch_template data
	echo '{ dc_api_version: "0.0.1", request: {describe:"CFEngine::sketch_template"} }' | $(CFAPI)
	@echo ...get Security::SSH data
	echo '{ dc_api_version: "0.0.1", request: {describe:"Security::SSH"} }' | $(CFAPI)
	@echo ...invalid request to install CFEngine::sketch_template: missing destination
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", source: "/home/tzz/source/design-center/sketches" } ] } }' | $(CFAPI)
	@echo ...invalid request to install CFEngine::sketch_template: bad version
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", version: "-1", target: "/home/tzz/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/sketches" } ] } }' | $(CFAPI)
	@echo ...valid request to install CFEngine::sketch_template
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", target: "/home/tzz/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/sketches" } ] } }' | $(CFAPI)
	@echo ...valid request to reinstall CFEngine::sketch_template
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", target: "/home/tzz/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/sketches" } ] } }' | $(CFAPI)
	@echo ...invalid request to uninstall CFEngine::sketch_template: missing target
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::sketch_template" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::sketch_template
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::sketch_template", target: "/home/tzz/.cfagent/inputs/sketches" } ] } }' | $(CFAPI)
	@echo ...valid request to install Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {install: { sketch: "Security::SSH", target: "/home/tzz/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/sketches" } } }' | $(CFAPI)
	@echo ...valid request to uninstall Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "Security::SSH", target: "/home/tzz/.cfagent/inputs/sketches" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "/home/tzz/.cfagent/inputs/sketches" } ] } }' | $(CFAPI)

	@echo ...invalid define
	echo '{ dc_api_version: "0.0.1", request: {define: [ "moo" ] } }' | $(CFAPI)
	@echo ...undefine no such definition
	echo '{ dc_api_version: "0.0.1", request: {undefine: [ "moo" ] } }' | $(CFAPI)
	@echo ...list definitions
	echo '{ dc_api_version: "0.0.1", request: {definitions: true } }' | $(CFAPI)
	@echo ...define moo
	echo '{ dc_api_version: "0.0.1", request: {define: { "moo": { data: "complex data here" } } } }' | $(CFAPI)
	@echo ...list definitions
	echo '{ dc_api_version: "0.0.1", request: {definitions: true } }' | $(CFAPI)
	@echo ...undefine moo
	echo '{ dc_api_version: "0.0.1", request: {undefine: [ "moo" ] } }' | $(CFAPI)
	@echo ...list definitions
	echo '{ dc_api_version: "0.0.1", request: {definitions: true } }' | $(CFAPI)

	@echo ...invalid define_environment
	echo '{ dc_api_version: "0.0.1", request: {define_environment: [ "DEV" ] } }' | $(CFAPI)
	@echo ...undefine_environment no such environment
	echo '{ dc_api_version: "0.0.1", request: {undefine_environment: [ "DEV" ] } }' | $(CFAPI)
	@echo ...list environments
	echo '{ dc_api_version: "0.0.1", request: {environments: true } }' | $(CFAPI)
	@echo ...define_incomplete environment DEV, missing activated
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "DEV": { test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...define_environment DEV
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "DEV": { activated: true, test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...list environments
	echo '{ dc_api_version: "0.0.1", request: {environments: true } }' | $(CFAPI)
	@echo ...undefine_environment DEV
	echo '{ dc_api_version: "0.0.1", request: {undefine_environment: [ "DEV" ] } }' | $(CFAPI)
	@echo ...list environments
	echo '{ dc_api_version: "0.0.1", request: {environments: true } }' | $(CFAPI)

	@echo '--- a full test of configuring Security::SSH --'

	@echo ...deactivate all activations
	echo '{ dc_api_version: "0.0.1", request: {deactivate: true } }' | $(CFAPI)
	@echo ...valid request to uninstall Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "Security::SSH", target: "/home/tzz/.cfagent/inputs/sketches" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "/home/tzz/.cfagent/inputs/sketches" } ] } }' | $(CFAPI)

	@echo ...valid request to install Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {install: { sketch: "Security::SSH", target: "/home/tzz/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/sketches" } } }' | $(CFAPI)
	@echo ...define Security::SSH run environment
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "ANYTIME": { activated: "!nosuchclass", test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...define Security::SSH parameters
	echo '{ dc_api_version: "0.0.1", request: {define: { "simple_ssh": { "Security::SSH": { params: { Protocol : "2", X11Forwarding : "yes", PermitRootLogin : "yes" } } } } } }' | $(CFAPI)
	@echo ...fail to activate Security::SSH with invalid run environments and simple_ssh parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { environment: null, params: ["simple_ssh" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { environment: "bad environment", params: ["simple_ssh" ] } } } }' | $(CFAPI)
	@echo ...fail to activate Security::SSH with valid run environments and invalid parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { environment: "ANYTIME", params: "bad params" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { environment: "ANYTIME", params: [ ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { environment: "ANYTIME", params: [ "undefined params" ] } } } }' | $(CFAPI)
	@echo ...activate Security::SSH with ANYTIME run environment and simple_ssh parameters
	@echo ...we could specify the bundle we want here with the bundle key
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { bundle: "nosuchbundle", target: "/home/tzz/.cfagent/inputs/sketches", environment: "ANYTIME", params: [ "simple_ssh" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { target: "/home/tzz/.cfagent/inputs/sketches", environment: "ANYTIME", params: [ "simple_ssh" ] } } } }' | $(CFAPI)

	@echo ...list installed
	echo '{ dc_api_version: "0.0.1", request: {list: true } }' | $(CFAPI)
	@echo ...generate the runfile
	echo '{ dc_api_version: "0.0.1", request: {regenerate: { } } }' | $(CFAPI)

api_cleanup:
	@echo ...deactivate first activation of Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {deactivate: { sketch: "Security::SSH", position: 0 } } }' | $(CFAPI)
	@echo ...deactivate all activations of Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {deactivate: "Security::SSH" } }' | $(CFAPI)
	@echo ...deactivate all activations
	echo '{ dc_api_version: "0.0.1", request: {deactivate: true } }' | $(CFAPI)

	@echo ...valid request to uninstall Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "Security::SSH", target: "/home/tzz/.cfagent/inputs/sketches" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "/home/tzz/.cfagent/inputs/sketches" } ] } }' | $(CFAPI)

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

run:
	$(RUNNER)

generate:
	$(CFSKETCH) --generate --runfile $(RUNFILE)

list:
	$(CFSKETCH) --list

search:
	$(CFSKETCH) --search

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

dclib:
	$(CFSKETCH) --install CFEngine::dclib

stdlib:
	$(CFSKETCH) --install CFEngine::stdlib

nonesuch:
	$(CFSKETCH) --install nonesuch

wordpress:
	@echo NOT IMPLEMENTED
