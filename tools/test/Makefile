PWD:=$(shell pwd)
DCDIR:=$(PWD)/../..
SOURCEDIR:=$(DCDIR)/sketches

CFPATH:=$(shell dirname $$(which cf-agent))

ifeq ($(CFPATH),)
  CFPATH:=/var/cfengine/bin
endif

ifeq ($(LOGNAME),root)
  API_DIR:=/var/cfengine/inputs
else
  API_DIR:=~/.cfagent/inputs
endif

ifneq ($(NOIGNORE),1)

	JSINDENT:=$(shell perl -MJavaScript::Beautifier=js_beautify -e"print 1")
	ifeq ($(JSINDENT),1)
	  CFAPI:=$(CFAPI) | perl -MJavaScript::Beautifier=js_beautify -e'print js_beautify(join "", <> )'
	else
# You should install the Perl JavaScript::Beautifier module (libjavascript-beautifier-perl in Debian)
	endif

	PYGMENTIZE:=$(shell which pygmentize)
	ifneq ($(PYGMENTIZE),)
	  CFAPI:=$(CFAPI) | $(PYGMENTIZE) -l js
	else
# You should install pygmentize, it rocks
	endif

endif

API_SKETCHDIR:=$(API_DIR)/sketches
API_RUNFILE:=$(API_SKETCHDIR)/meta/api-runfile.cf

ifeq ($(VV),1)
  EXTRA:=--veryverbose
endif

ifeq ($(V),1)
  EXTRA:=--verbose=any
endif

ifneq ($(A),)
  EXTRA:= $(EXTRA) --activated=$(A)
else
  EXTRA:= $(EXTRA) --activated
endif

ifneq ($(FILTER),)
  EXTRA:= $(EXTRA) --filter=$(FILTER)
endif

CFSKETCH_BASE:=$(PWD)/../cf-sketch/cf-sketch.pl --installsource=$(SOURCEDIR)/cfsketches.json
CFSKETCH:=$(CFSKETCH_BASE) --make_cfsketches --inputs $(DCDIR); $(CFSKETCH_BASE) --expert --cfpath=$(CFPATH) $(EXTRA) --force --inputs $(API_DIR) --relocate_path sketches
CFSKETCH_DA:=rm $(API_RUNFILE); $(CFSKETCH) --deactivate-all --generate -v
RUNNER:=$(CFPATH)/cf-agent -KI -f $(API_DIR)/promises.cf
CFAPI:=$(PWD)/../cf-sketch/cf-dc-api.pl $(PWD)/../cf-sketch/config.json

regenerate_readme:
	$(CFSKETCH_BASE) --make_readme --inputs $(DCDIR)

regenerate_cfsketches:
	$(CFSKETCH_BASE) --make_cfsketches --inputs $(DCDIR)

regenerate: regenerate_cfsketches regenerate_readme

do:

api_test:
	echo '{ dc_api_version: "3.6.0", request: {deactivate: true } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "path_override": { activated: true, test: true, verbose: true, qa: true, path_prefix: "/tmp/contain" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "default": { activated: true, test: false, verbose: false } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {install: [ { sketch: "CFEngine::dclib", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {install: [ { sketch: "Applications::Memcached", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define: { "memcached_11111": { "Applications::Memcached": { port: 11111 } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Applications::Memcached": { priority: "001", environment: "path_override", params: [ "memcached_11111" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Applications::Memcached": { priority: "002", environment: "default", params: [ "memcached_11111" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {regenerate: { } } }' | $(CFAPI)

api_activate:
	@echo ...install CFEngine::sketch_template, deactivate all, activate just CFEngine::sketch_template with some metadata, then generate the runfile
	echo '{ dc_api_version: "3.6.0", request: {install: [ { sketch: "CFEngine::sketch_template", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {deactivate: true } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {activate: { "CFEngine::sketch_template": { target: "$(API_SKETCHDIR)", identifier: "my special identifier", metadata: { myvar: "myvalue" }, environment: "testing", params: [ "simple_sketch" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {regenerate: { } } }' | $(CFAPI)
	@echo ...deactivate my special identifier
	echo '{ dc_api_version: "3.6.0", request: {deactivate: "my special identifier" } }' | $(CFAPI)

api_validations:
	@echo ...list validations
	echo '{ dc_api_version: "3.6.0", request: {validations: 1 } }' | $(CFAPI)
	@echo ...define a choice-of validation with choice and derived
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { AB: { choice: [ "A", "B" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { C: { choice: [ "C" ] } } } }' | $(CFAPI)
	mkdir -p /var/tmp
	echo hamburger > /var/tmp/roles.txt
	echo cheeseburger >> /var/tmp/roles.txt
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { FILE: { choice: { file: "/var/tmp/roles.txt" } } } } }' | $(CFAPI)
	@echo ...define some basic validations
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { IPv4_local: { valid_ipv4: "10.0.0/24", invalid_ipv4: "10.3.6.0" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { IPv4: { valid_ipv4: "0.0.0.0/0" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { NONEMPTY_STRING: { valid_regex: "." } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { OCTAL: { valid_regex: "^[0-7]+$$" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { DIGITS: { valid_regex: "^[0-9]+$$" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { NUMBER: { derived: [ "DIGITS" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { 8BIT_NUMBER: { minimum_value: 0, maximum_value: 255 } } } }' | $(CFAPI)
	@echo ...define a derived validation
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { URL_HTTP_OR_FTP: { derived: [ "URL" ], valid_regex: "^(ftp|https?)://.+" } } } }' | $(CFAPI)
	@echo ...define some compound types
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { ARRAY_OF_NUMBERS_TO_URLS: { array_k: [ "NUMBER" ], array_v: [ "URL" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { LIST_OF_NUMBERS: { list: [ "NUMBER" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { LIST_OF_LIST_OF_NUMBERS: { list: [ "LIST_OF_NUMBERS" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { ARRAY_OF_NONEMPTY_STRINGS_TO_LIST_OF_LIST_OF_NUMBERS: { array_k: [ "NONEMPTY_STRING" ], array_v: [ "LIST_OF_LIST_OF_NUMBERS" ] } } } }' | $(CFAPI)

	echo '{ dc_api_version: "3.6.0", request: {define_validation: { UID: { derived: [ "NONEMPTY_STRING" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { GID: { derived: [ "NONEMPTY_STRING" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { MOG_SEQUENCE: { sequence: [ "OCTAL", "UID", "GID"  ] } } } }' | $(CFAPI)

	@echo ...define complicated URL regex
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { URL: { valid_regex: "^[A-Za-z]{3,9}://.+" } } } }' | $(CFAPI)

	@echo .. define array validation with strict
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { ARRAY_STRICT: { array_k: [ "NONEMPTY_STRING" ], array_v: [ "NONEMPTY_STRING" ], array_map_strict: {"action":"NONEMPTY_STRING","days":"NONEMPTY_STRING"} } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { ARRAY_PERMISSIVE: { array_k: [ "NONEMPTY_STRING" ], array_v: [ "NONEMPTY_STRING" ], array_map_permissive: {"action":"NONEMPTY_STRING","days":"DIGITS" } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_validation: { ARRAY_STRICT_PERMISSIVE: { array_k: [ "NONEMPTY_STRING" ], array_v: [ "NONEMPTY_STRING" ],  array_map_strict: {"action":"NONEMPTY_STRING","days":"DIGITS" },array_map_permissive: {"action":"NONEMPTY_STRING","days":"DIGITS" } } } } }' | $(CFAPI)


api_validate:
	@echo ...now validate choices
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "AB", data: "A" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "AB", data: "" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "C", data: "C" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "FILE", data: "hamburger" } } }' | $(CFAPI)

	@echo ...now validate numeric data
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "8BIT_NUMBER", data: 100 } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "8BIT_NUMBER", data: 0 } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "8BIT_NUMBER", data: -1 } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "8BIT_NUMBER", data: 255 } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "8BIT_NUMBER", data: 256 } } }' | $(CFAPI)

	@echo ...now validate regex data
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "OCTAL", data: "100" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "OCTAL", data: "800" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "OCTAL", data: "" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "URL_HTTP_OR_FTP", data: "" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "URL_HTTP_OR_FTP", data: "http://github.com?p1=v1&p2=v2" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "URL_HTTP_OR_FTP", data: "file:///here" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "NONEMPTY_STRING", data: "hello" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "NONEMPTY_STRING", data: "" } } }' | $(CFAPI)

	@echo ...now validate IPs
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "IPv4_local", data: "10." } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "IPv4_local", data: "10.3.6.0" } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "IPv4_local", data: "10.0.0.99" } } }' | $(CFAPI)

	@echo ...try a list where a scalar should go
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "8BIT_NUMBER", data: [256] } } }' | $(CFAPI)

	@echo ...now a list of numbers
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "LIST_OF_NUMBERS", data: {"hello":256} } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "LIST_OF_NUMBERS", data: 256 } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "LIST_OF_NUMBERS", data: [] } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "LIST_OF_NUMBERS", data: [256] } } }' | $(CFAPI)

	@echo ...a sequence
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "MOG_SEQUENCE", data: {"hello":256} } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "MOG_SEQUENCE", data: 256 } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "MOG_SEQUENCE", data: [256] } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "MOG_SEQUENCE", data: [254, "you", "me"] } } }' | $(CFAPI)

	@echo ...a key-value array
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: {"hello":256} } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: 256 } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: [256] } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: { "20": "http://this.that", "30": "not a URL" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: { "20": "http://this.that", "30": "http://this.that2" } } } }' | $(CFAPI)

	@echo ...a non-existing validation
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "FOOBAR_BAZ", data: {"hello":256} } } }' | $(CFAPI)

	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "ARRAY_STRICT", data: {"days":"256",'action':"12"} } } }' | $(CFAPI)

	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "ARRAY_STRICT", data: {"days":"256",'action':"12","extra":"fail"} } } }' | $(CFAPI)


	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "ARRAY_PERMISSIVE", data: {"days":22,'action':"12","extra":"what what"} } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {validate: { validation: "ARRAY_STRICT_PERMISSIVE", data: {"days":22,'action':"12"} } } }' | $(CFAPI)



api_environments:
	@echo ...show all environments
	echo '{ dc_api_version: "3.6.0", request: {environments:true} }' | $(CFAPI)
	@echo ...define testing run environment
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "testing": { activated: true, test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...undefine testing run environment
	echo '{ dc_api_version: "3.6.0", request: {undefine_environment: [ "testing" ] } }' | $(CFAPI)
	@echo ...define testing run environment with include criteria... note that exclude criteria are ignored...
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "testing": { activated: [], test: true, verbose: true } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "testing": { activated: {}, test: true, verbose: true } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "testing": { activated: {include:"x"}, test: true, verbose: true } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "testing": { activated: {exclude:"x"}, test: true, verbose: true } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "testing": { activated: {include:["x", "y.*"], exclude: ["b", "c"]}, test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...undefine testing run environment
	echo '{ dc_api_version: "3.6.0", request: {undefine_environment: [ "testing" ] } }' | $(CFAPI)

api_definitions:
	@echo ...show all definiions
	echo '{ dc_api_version: "3.6.0", request: {definitions:true} }' | $(CFAPI)
	@echo ...define some parameters
	echo '{ dc_api_version: "3.6.0", request: {define: { "vcs_base": { "VCS::vcs_mirror": { options: { parent_dir: { owner: { "function": "getenv", "args": ["LOGNAME", "128"] }, group: { "function": "getenv", "args": ["LOGNAME", "128"] }, perms: "755", ensure: true }, nowipe: true, vcs: { runas: { "function": "getenv", "args": ["LOGNAME", "128"] }, umask: "000" } } } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define: { "git_mirror_core": { "VCS::vcs_mirror": { vcs: "/usr/bin/git", path: "/tmp/q/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git" }, "Security::SSH": { params: { "PermitRootLogin": "yes" } } } } } }' | $(CFAPI)
	@echo ...undefine a set of parameters
	echo '{ dc_api_version: "3.6.0", request: {undefine: ["vcs_base"] } }' | $(CFAPI)

api_search:
	@echo ...describe Security::SSH
	echo '{ dc_api_version: "3.6.0", request: {describe:"Security::SSH"} }' | $(CFAPI)
	@echo ...list installed
	echo '{ dc_api_version: "3.6.0", request: {list: true } }' | $(CFAPI)
	@echo ...list installed matching Cloud or CFEngine
	echo '{ dc_api_version: "3.6.0", request: {list: [["name", "matches", "(Cloud|CFEngine|Security)"]] } }' | $(CFAPI)
	@echo ...list and describe any installed sketch matching ping
	echo '{ dc_api_version: "3.6.0", request: {describe: true, list: [["name", "matches", "ping"]] } }' | $(CFAPI)
	@echo ...dynamically generate a README for any installed sketch matching ping
	echo '{ dc_api_version: "3.6.0", request: {describe: "README", list: [["name", "matches", "ping"]] } }' | $(CFAPI)
	@echo ...search none
	echo '{ dc_api_version: "3.6.0", request: {search: false } }' | $(CFAPI)
	@echo ...search all available
	echo '{ dc_api_version: "3.6.0", request: {search: true } }' | $(CFAPI)
	@echo ...search all matching Cloud
	echo '{ dc_api_version: "3.6.0", request: {search: "Cloud" } }' | $(CFAPI)
	@echo ...search all matching Security
	echo '{ dc_api_version: "3.6.0", request: {search: ["Security"] } }' | $(CFAPI)
	@echo ...search available matching cloud or cfengine via regex
	echo '{ dc_api_version: "3.6.0", request: {search: [["name", "matches", "(Cloud|CFEngine)"]] } }' | $(CFAPI)
	@echo ...search available matching cloud or cfengine via data alternation
	echo '{ dc_api_version: "3.6.0", request: {search: [["name", "matches", "Cloud"], ["name", "matches", "CFEngine"]] } }' | $(CFAPI)
	@echo ...search available matching cloud in the tags
	echo '{ dc_api_version: "3.6.0", request: {search: [["tags", "matches", "cloud"]] } }' | $(CFAPI)

api:
	@echo '--- a full test of configuring VCS::vcs_mirror and reporting the directories it mirrors --'

	@echo ...define testing run environment
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "testing": { activated: true, test: null, verbose: true } } } }' | $(CFAPI)

	@echo ...deactivate all activations
	echo '{ dc_api_version: "3.6.0", request: {deactivate: true } }' | $(CFAPI)

	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "3.6.0", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)

	@echo ...valid request to install CFEngine::sketch_template and VCS::vcs_mirror
	echo '{ dc_api_version: "3.6.0", request: {install: [ { sketch: "CFEngine::sketch_template", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" }, { sketch: "VCS::vcs_mirror", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)

	@echo ...define CFEngine::sketch_template incomplete_sketch parameters
	echo '{ dc_api_version: "3.6.0", request: {define: { "incomplete_sketch": { "CFEngine::sketch_template": { myboolean: true, myarray: { a: 1, b: 3, c: 3 } } } } } }' | $(CFAPI)
	@echo define VCS::vcs_mirror parameters
	echo '{ dc_api_version: "3.6.0", request: {define: { "vcs_base": { "VCS::vcs_mirror": { options: { parent_dir: { owner: { "function": "getenv", "args": ["LOGNAME", "128"] }, group: { "function": "getenv", "args": ["LOGNAME", "128"] }, perms: "755", ensure: true }, nowipe: true, vcs: { runas: { "function": "getenv", "args": ["LOGNAME", "128"] }, umask: "000" } } } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define: { "git_mirror_core": { "VCS::vcs_mirror": { vcs: "/usr/bin/git", path: "/tmp/q/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git" } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define: { "svn_mirror_thrift": { "VCS::vcs_mirror": { vcs: "/usr/bin/svn", path: "/tmp/thrift-perl-lib", branch: "", origin: "http://svn.apache.org/repos/asf/thrift/attic/trunk/lib/perl", options: { parent_dir: { ensure: false } }  } } } } }' | $(CFAPI)

	@echo ...activate VCS::vcs_mirror with testing run environment and vcs_base+git_mirror_core and vcs_base+svn_mirror_thrift parameters
	echo '{ dc_api_version: "3.6.0", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "vcs_base", "git_mirror_core" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "vcs_base", "svn_mirror_thrift" ] } } } }' | $(CFAPI)

	@echo ...compose some sketch values in other sketches: sketch composition
	echo '{ dc_api_version: "3.6.0", request: {decompose: "mirror_to_template_1" } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {compose: { mirror_to_template_1: { destination_sketch: "CFEngine::sketch_template", destination_list: "mylist", source_sketch: "VCS::vcs_mirror", source_scalar: "deploy_path" }, mirror_to_template_2: { destination_sketch: "CFEngine::sketch_template", destination_scalar: "myip", source_sketch: "VCS::vcs_mirror", source_scalar: "deploy_path" } } } }' | $(CFAPI)

	@echo ...activate CFEngine::sketch_template with testing run environment and incomplete_sketch parameters, with the previous compositions providing the glue
	echo '{ dc_api_version: "3.6.0", request: {activate: { "CFEngine::sketch_template": { compositions: [ "mirror_to_template_1", "mirror_to_template_2",], target: "$(API_SKETCHDIR)", environment: "testing", params: [ "incomplete_sketch" ] } } } }' | $(CFAPI)

	@echo ...generate the runfile
	echo '{ dc_api_version: "3.6.0", request: {regenerate: { } } }' | $(CFAPI)

api2:
	@echo '--- a full test of configuring Security::SSH, CFEngine::sketch_template, and VCS::vcs_mirror --'

	@echo ...define ANYTIME run environment
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "ANYTIME": { activated: "!nosuchclass", test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...define testing run environment
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "testing": { activated: true, test: true, verbose: true } } } }' | $(CFAPI)

	@echo ...deactivate all activations
	echo '{ dc_api_version: "3.6.0", request: {deactivate: true } }' | $(CFAPI)

	@echo ...valid request to install Security::SSH, CFEngine::sketch_template, and VCS::vcs_mirror
	echo '{ dc_api_version: "3.6.0", request: {install: [ { sketch: "Security::SSH", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" }, { sketch: "CFEngine::sketch_template", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" }, { sketch: "VCS::vcs_mirror", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)

	@echo ...define Security::SSH simple_ssh and CFEngine::sketch_template simple_sketch parameters
	echo '{ dc_api_version: "3.6.0", request: {define: { "simple_sketch": { "CFEngine::sketch_template": { myboolean: true, myip: "13.6.0.0", mylist: [ 1, 2, 3 ], myarray: { a: 1, b: 3, c: 3 } } }, "simple_ssh": { "Security::SSH": { params: { Protocol : "2", X11Forwarding : "yes", PermitRootLogin : "yes" } } } } } }' | $(CFAPI)
	@echo define VCS::vcs_mirror parameters
	echo '{ dc_api_version: "3.6.0", request: {define: { "vcs_base": { "VCS::vcs_mirror": { options: { parent_dir: { owner: { "function": "getenv", "args": ["LOGNAME", "128"] }, group: { "function": "getenv", "args": ["LOGNAME", "128"] }, perms: "755", ensure: true }, nowipe: true, vcs: { runas: { "function": "getenv", "args": ["LOGNAME", "128"] }, umask: "000" } } } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define: { "git_mirror_core": { "VCS::vcs_mirror": { vcs: "/usr/bin/git", path: "/tmp/q/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git" } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define: { "svn_mirror_thrift": { "VCS::vcs_mirror": { vcs: "/usr/bin/svn", path: "/tmp/thrift-perl-lib", branch: "", origin: "http://svn.apache.org/repos/asf/thrift/attic/trunk/lib/perl", options: { parent_dir: { ensure: false } }  } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {define: { "git_invalid": { "VCS::vcs_mirror": { path: "/tmp/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git", options: { umask: "000" }, vcs: "/no/such/versioning_system" } } } } }' | $(CFAPI)

	@echo ...activate Security::SSH with ANYTIME run environment and simple_ssh parameters
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Security::SSH": { target: "$(API_SKETCHDIR)", environment: "ANYTIME", params: [ "simple_ssh" ] } } } }' | $(CFAPI)
	@echo ...activate CFEngine::sketch_template with testing run environment and simple_sketch parameters
	echo '{ dc_api_version: "3.6.0", request: {activate: { "CFEngine::sketch_template": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "simple_sketch" ] } } } }' | $(CFAPI)
	@echo ...activate VCS::vcs_mirror with testing run environment and vcs_base+git_mirror_core and vcs_base+svn_mirror_thrift parameters
	echo '{ dc_api_version: "3.6.0", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "vcs_base", "git_mirror_core" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "vcs_base", "svn_mirror_thrift" ] } } } }' | $(CFAPI)
	@echo ...activate VCS::vcs_mirror with testing run environment and git_invalid parameters
	echo '{ dc_api_version: "3.6.0", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "git_invalid" ] } } } }' | $(CFAPI)

	@echo ...list installed
	echo '{ dc_api_version: "3.6.0", request: {list: true } }' | $(CFAPI)
	@echo ...generate the runfile
	echo '{ dc_api_version: "3.6.0", request: {regenerate: { } } }' | $(CFAPI)

api_basics:
	@echo ...invalid data
	echo 'broken json' | $(CFAPI)
	@echo ...invalid API version
	echo '{ dc_api_version: "5.0.2" }' | $(CFAPI)
	@echo ...debug mode
	echo '{ dc_api_version: "3.6.0", debug: true }' | $(CFAPI)
	@echo ...empty request
	echo '{ dc_api_version: "3.6.0", request: { } }' | $(CFAPI)
	@echo ...list installed
	echo '{ dc_api_version: "3.6.0", request: {list: true } }' | $(CFAPI)
	@echo ...list installed matching Cloud or CFEngine
	echo '{ dc_api_version: "3.6.0", request: {list: [["name", "matches", "(Cloud|CFEngine|Security)"]] } }' | $(CFAPI)
	@echo ...dynamically generate a README for any installed sketch matching ping
	echo '{ dc_api_version: "3.6.0", request: {describe: "README", list: [["name", "matches", "ping"]] } }' | $(CFAPI)
	@echo ...search all available
	echo '{ dc_api_version: "3.6.0", request: {search: true } }' | $(CFAPI)
	@echo ...search available matching cloud or cfengine via regex
	echo '{ dc_api_version: "3.6.0", request: {search: [["name", "matches", "(Cloud|CFEngine)"]] } }' | $(CFAPI)
	@echo ...search available matching cloud or cfengine via data alternation
	echo '{ dc_api_version: "3.6.0", request: {search: [["name", "matches", "Cloud"], ["name", "matches", "CFEngine"]] } }' | $(CFAPI)
	@echo ...get CFEngine::sketch_template data
	echo '{ dc_api_version: "3.6.0", request: {describe:"CFEngine::sketch_template"} }' | $(CFAPI)
	@echo ...get Security::SSH data
	echo '{ dc_api_version: "3.6.0", request: {describe:"Security::SSH"} }' | $(CFAPI)
	@echo ...invalid request to install CFEngine::sketch_template: missing destination
	echo '{ dc_api_version: "3.6.0", request: {install: [ { sketch: "CFEngine::sketch_template", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	@echo ...invalid request to install CFEngine::sketch_template: bad version
	echo '{ dc_api_version: "3.6.0", request: {install: [ { sketch: "CFEngine::sketch_template", version: "-1", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to install CFEngine::sketch_template
	echo '{ dc_api_version: "3.6.0", request: {install: [ { sketch: "CFEngine::sketch_template", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to reinstall CFEngine::sketch_template
	echo '{ dc_api_version: "3.6.0", request: {install: [ { sketch: "CFEngine::sketch_template", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	@echo ...invalid request to uninstall CFEngine::sketch_template: missing target
	echo '{ dc_api_version: "3.6.0", request: {uninstall: [ { sketch: "CFEngine::sketch_template" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::sketch_template
	echo '{ dc_api_version: "3.6.0", request: {uninstall: [ { sketch: "CFEngine::sketch_template", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to install Security::SSH
	echo '{ dc_api_version: "3.6.0", request: {install: { sketch: "Security::SSH", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } } }' | $(CFAPI)
	@echo ...valid request to uninstall Security::SSH
	echo '{ dc_api_version: "3.6.0", request: {uninstall: [ { sketch: "Security::SSH", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "3.6.0", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)

	@echo ...invalid define
	echo '{ dc_api_version: "3.6.0", request: {define: [ "moo" ] } }' | $(CFAPI)
	@echo ...undefine no such definition
	echo '{ dc_api_version: "3.6.0", request: {undefine: [ "moo" ] } }' | $(CFAPI)
	@echo ...list definitions
	echo '{ dc_api_version: "3.6.0", request: {definitions: true } }' | $(CFAPI)
	@echo ...define moo
	echo '{ dc_api_version: "3.6.0", request: {define: { "moo": { data: "complex data here" } } } }' | $(CFAPI)
	@echo ...list definitions
	echo '{ dc_api_version: "3.6.0", request: {definitions: true } }' | $(CFAPI)
	@echo ...undefine moo
	echo '{ dc_api_version: "3.6.0", request: {undefine: [ "moo" ] } }' | $(CFAPI)
	@echo ...list definitions
	echo '{ dc_api_version: "3.6.0", request: {definitions: true } }' | $(CFAPI)

	@echo ...invalid define_environment
	echo '{ dc_api_version: "3.6.0", request: {define_environment: [ "DEV" ] } }' | $(CFAPI)
	@echo ...undefine_environment no such environment
	echo '{ dc_api_version: "3.6.0", request: {undefine_environment: [ "DEV" ] } }' | $(CFAPI)
	@echo ...list environments
	echo '{ dc_api_version: "3.6.0", request: {environments: true } }' | $(CFAPI)
	@echo ...define_incomplete environment DEV, missing activated
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "DEV": { test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...define_environment DEV
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "DEV": { activated: true, test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...list environments
	echo '{ dc_api_version: "3.6.0", request: {environments: true } }' | $(CFAPI)
	@echo ...undefine_environment DEV
	echo '{ dc_api_version: "3.6.0", request: {undefine_environment: [ "DEV" ] } }' | $(CFAPI)
	@echo ...list environments
	echo '{ dc_api_version: "3.6.0", request: {environments: true } }' | $(CFAPI)

	@echo '--- a full test of configuring Security::SSH --'

	@echo ...deactivate all activations
	echo '{ dc_api_version: "3.6.0", request: {deactivate: true } }' | $(CFAPI)
	@echo ...valid request to uninstall Security::SSH
	echo '{ dc_api_version: "3.6.0", request: {uninstall: [ { sketch: "Security::SSH", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "3.6.0", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)

	@echo ...valid request to install Security::SSH
	echo '{ dc_api_version: "3.6.0", request: {install: { sketch: "Security::SSH", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } } }' | $(CFAPI)
	@echo ...define Security::SSH run environment
	echo '{ dc_api_version: "3.6.0", request: {define_environment: { "ANYTIME": { activated: "!nosuchclass", test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...define Security::SSH parameters
	echo '{ dc_api_version: "3.6.0", request: {define: { "simple_ssh": { "Security::SSH": { params: { Protocol : "2", X11Forwarding : "yes", PermitRootLogin : "yes" } } } } } }' | $(CFAPI)
	@echo ...fail to activate Security::SSH with invalid run environments and simple_ssh parameters
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Security::SSH": { environment: null, params: ["simple_ssh" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Security::SSH": { environment: "bad environment", params: ["simple_ssh" ] } } } }' | $(CFAPI)
	@echo ...fail to activate Security::SSH with valid run environments and invalid parameters
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Security::SSH": { environment: "ANYTIME", params: "bad params" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Security::SSH": { environment: "ANYTIME", params: [ ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Security::SSH": { environment: "ANYTIME", params: [ "undefined params" ] } } } }' | $(CFAPI)
	@echo ...activate Security::SSH with ANYTIME run environment and simple_ssh parameters
	@echo ...we could specify the bundle we want here with the bundle key
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Security::SSH": { bundle: "nosuchbundle", target: "$(API_SKETCHDIR)", environment: "ANYTIME", params: [ "simple_ssh" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "3.6.0", request: {activate: { "Security::SSH": { target: "$(API_SKETCHDIR)", environment: "ANYTIME", params: [ "simple_ssh" ] } } } }' | $(CFAPI)

	@echo ...list installed
	echo '{ dc_api_version: "3.6.0", request: {list: true } }' | $(CFAPI)
	@echo ...generate the runfile
	echo '{ dc_api_version: "3.6.0", request: {regenerate: { } } }' | $(CFAPI)

api_cleanup:
	@echo ...deactivate first activation of Security::SSH
	echo '{ dc_api_version: "3.6.0", request: {deactivate: { sketch: "Security::SSH", position: 0 } } }' | $(CFAPI)
	@echo ...deactivate all activations of Security::SSH
	echo '{ dc_api_version: "3.6.0", request: {deactivate: "Security::SSH" } }' | $(CFAPI)
	@echo ...deactivate all activations
	echo '{ dc_api_version: "3.6.0", request: {deactivate: true } }' | $(CFAPI)

	@echo ...valid request to uninstall Security::SSH
	echo '{ dc_api_version: "3.6.0", request: {uninstall: [ { sketch: "Security::SSH", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "3.6.0", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)

api_regenerate_index:
	echo '{ dc_api_version: "3.6.0", request: {regenerate_index: "~/source/cfengine/design-center/sketches" } }' | $(CFAPI)

# note that all tests are run if T is not set via "make api_selftest T=testname"
api_selftest:
	echo '{ dc_api_version: "3.6.0", request: { selftest: "$(T)" } }' | $(CFAPI)

api_selftest_junit:
	echo '{ dc_api_version: "3.6.0", request: { selftest: "$(T)" } }' | env CF_AGENT_OVERRIDE=/no/such/file CF_PROMISES_OVERRIDE=/no/such/file CF_VERSION_OVERRIDE=3.5.2 $(CFAPI) | ./json2junit.pl

run:
	$(RUNNER)

generate:
	$(CFSKETCH) --generate $(API_DIR)

list:
	$(CFSKETCH) --list $(API_DIR)

search:
	$(CFSKETCH) --search $(API_DIR)

test:
	$(CFSKETCH) --install $(SKETCH) --apitest $(SKETCH) --noignore -v $(API_DIR)

testinstalled:
	$(CFSKETCH) --apitest $(SKETCH) --noignore -v $(API_DIR)

testallinstalled:
	$(CFSKETCH) --apitest 1 --noignore -v $(API_DIR)

testcoverage:
	$(CFSKETCH) --apitest 1 --coverage --noignore -v $(API_DIR)

# individual sketch tests follow

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

aws_ec2:
	$(CFSKETCH_DA) --install Cloud::Services::AWS::EC2 --activate Cloud::Services::AWS::EC2=$(SOURCEDIR)/cloud/aws_ec2/params/demo.json
	$(RUNNER)

aws_s3:
	$(CFSKETCH_DA) --install Cloud::Services::AWS::S3 --activate Cloud::Services::AWS::S3=$(SOURCEDIR)/cloud/aws_s3/params/demo.json
	$(RUNNER)

aws_sdb:
	$(CFSKETCH_DA) --install Cloud::Services::AWS::SDB --activate Cloud::Services::AWS::SDB=$(SOURCEDIR)/cloud/aws_sdb/params/demo.json
	$(RUNNER)

vmware:
	$(CFSKETCH_DA) --install Cloud::Services::VMWare --activate Cloud::Services::VMWare=$(SOURCEDIR)/cloud/vmware/params/demo.json
	$(RUNNER)

openstack:
	$(CFSKETCH_DA) --install Cloud::Services::OpenStack --activate Cloud::Services::OpenStack=$(SOURCEDIR)/cloud/openstack/params/demo.json
	$(RUNNER)

wordpress:
	@echo NOT IMPLEMENTED

mysql_client:
	$(CFSKETCH_DA) --install Database::Install::MySQL --activate Database::Install::MySQL=$(SOURCEDIR)/databases/mysql_install/params/demo_client.json
	$(RUNNER)

mysql_server:
	$(CFSKETCH_DA) --install Database::Install::MySQL --activate Database::Install::MySQL=$(SOURCEDIR)/databases/mysql_install/params/demo_server.json
	$(RUNNER)

mysql_simple_client:
	$(CFSKETCH_DA) --install Database::Install::MySQL::Simple --activate Database::Install::MySQL::Simple=$(SOURCEDIR)/databases/mysql_install_simple/params/demo_client.json
	$(RUNNER)

mysql_simple_server:
	$(CFSKETCH_DA) --install Database::Install::MySQL::Simple --activate Database::Install::MySQL::Simple=$(SOURCEDIR)/databases/mysql_install_simple/params/demo_server.json
	$(RUNNER)

postgresql_client:
	$(CFSKETCH_DA) --install Database::Install::PostgreSQL --activate Database::Install::PostgreSQL=$(SOURCEDIR)/databases/postgresql_install/params/demo_client.json
	$(RUNNER)

postgresql_server:
	$(CFSKETCH_DA) --install Database::Install::PostgreSQL --activate Database::Install::PostgreSQL=$(SOURCEDIR)/databases/postgresql_install/params/demo_server.json
	$(RUNNER)

postgresql_simple_client:
	$(CFSKETCH_DA) --install Database::Install::PostgreSQL::Simple --activate Database::Install::PostgreSQL::Simple=$(SOURCEDIR)/databases/postgresql_install_simple/params/demo_client.json
	$(RUNNER)

postgresql_simple_server:
	$(CFSKETCH_DA) --install Database::Install::PostgreSQL::Simple --activate Database::Install::PostgreSQL::Simple=$(SOURCEDIR)/databases/postgresql_install_simple/params/demo_server.json
	$(RUNNER)

sqlite:
	$(CFSKETCH_DA) --install Database::Install::SQLite --activate Database::Install::SQLite=$(SOURCEDIR)/databases/sqlite_install/params/demo.json
	$(RUNNER)

snmpwalk:
	$(CFSKETCH_DA) --install Monitoring::SNMP::Walk --activate Monitoring::SNMP::Walk=$(SOURCEDIR)/monitoring/snmp/snmpwalk/params/demo.json
	$(RUNNER)

generic_services:
	$(CFSKETCH_DA) --install Services::Generic --activate Services::Generic=$(SOURCEDIR)/utilities/generic_services/params/demo.json
	$(RUNNER)

packages_debian_single:
	$(CFSKETCH_DA) --install Packages::Debian::single --activate Packages::Debian::single=$(SOURCEDIR)/package_management/debian/single/params/test.json
	(cd $(SOURCEDIR); make); $(PWD)/../cf-sketch/cf-sketch.pl --expert --apitest Packages::Debian::single
	$(RUNNER)

access:
	$(CFSKETCH_DA) --install System::access --activate System::access=$(SOURCEDIR)/security/access/params/example.json
	$(RUNNER)

data_classes:
	$(CFSKETCH_DA) --install Data::Classes --activate Data::Classes=$(SOURCEDIR)/utilities/data_classes/params/demo.json
	$(RUNNER)

motd:
	$(CFSKETCH_DA) --install System::motd --activate System::motd=$(SOURCEDIR)/system/motd/params/example.json
	$(RUNNER)

bad_input_file:
	$(CFSKETCH_DA) --install Data::Classes --activate Data::Classes=/no/such/file
	$(RUNNER)

tidy_dir:
	$(CFSKETCH_DA) --install Utilities::tidy_dir --activate Utilities::tidy_dir=$(SOURCEDIR)/utilities/tidy_dir/params/test_defaults.json
	$(RUNNER)
	$(CFSKETCH_DA) --install Utilities::tidy_dir --activate Utilities::tidy_dir=$(SOURCEDIR)/utilities/tidy_dir/params/demo.json
	$(RUNNER)

memcached:
	$(CFSKETCH_DA) --install Applications::Memcached --activate Applications::Memcached=$(SOURCEDIR)/applications/memcached/params/demo.json
	$(RUNNER)

redis:
	$(CFSKETCH_DA) --install Applications::Redis --activate Applications::Redis=$(SOURCEDIR)/applications/redis/params/demo.json
	$(RUNNER)

gencert:
	$(CFSKETCH_DA) --install Utilities::OpenSSL::GenCert --activate Utilities::OpenSSL::GenCert=$(SOURCEDIR)/utilities/openssl/gencert/params/demo.json
	$(RUNNER)

syslog:
	$(CFSKETCH_DA) --install System::syslog --activate System::syslog=$(SOURCEDIR)/system/syslog/params/demo.json
	$(RUNNER)

routes:
	$(CFSKETCH_DA) --install System::Routes --activate System::Routes=$(SOURCEDIR)/system/routes/params/demo.json
	$(RUNNER)

logrotate:
	$(CFSKETCH_DA) --install System::Logrotate --activate System::Logrotate=$(SOURCEDIR)/system/logrotate/params/demo.json
	$(RUNNER)

ntp:
	$(CFSKETCH_DA) --install Networking::NTP::Client --activate Networking::NTP::Client=$(SOURCEDIR)/networking/ntp/client/params/demo.json
	$(RUNNER)

iptables:
	$(CFSKETCH_DA) --install Security::IPTables::Filter --activate Security::IPTables::Filter=$(SOURCEDIR)/security/iptables/filter/params/demo.json
	$(RUNNER)

zabbix:
	$(CFSKETCH_DA) --install Applications::Zabbix::Agent --activate Applications::Zabbix::Agent=$(SOURCEDIR)/applications/zabbix/agent/params/demo.json
	$(RUNNER)

epel:
	$(CFSKETCH_DA) --install Repository::EPEL --activate Repository::EPEL=$(SOURCEDIR)/package_management/epel/params/demo.json
	$(RUNNER)

nrpe:
	$(CFSKETCH_DA) --install Applications::Nagios::NRPE --activate Applications::Nagios::NRPE=$(SOURCEDIR)/applications/nagios/nrpe/params/demo.json
	$(RUNNER)

packages_removed:
	$(CFSKETCH_DA) --install Packages::removed --activate Packages::removed=$(SOURCEDIR)/package_management/packages_removed/params/demo.json
	$(RUNNER)

packages_removed_file:
	echo 'screen' > /tmp/packages.dat
	echo 'zsh' >> /tmp/packages.dat
	echo 'nosuchpackage' >> /tmp/packages.dat
	$(CFSKETCH_DA) --install Packages::removed --activate Packages::removed=$(SOURCEDIR)/package_management/packages_removed/params/demo_file.json
	$(RUNNER)

packages_installed:
	$(CFSKETCH_DA) --install Packages::installed --activate Packages::installed=$(SOURCEDIR)/package_management/packages_installed/params/demo.json
	$(RUNNER)

packages_installed_file:
	echo 'screen' > /tmp/packages.dat
	echo 'zsh' >> /tmp/packages.dat
	echo 'nosuchpackage' >> /tmp/packages.dat
	$(CFSKETCH_DA) --install Packages::installed --activate Packages::installed=$(SOURCEDIR)/package_management/packages_installed/params/demo_file.json
	$(RUNNER)

packages_installed_url:
	touch /tmp/mypackage
	$(CFSKETCH_DA) --install Packages::installed --activate Packages::installed=$(SOURCEDIR)/package_management/packages_installed/params/demo_url.json
	$(RUNNER)

# this is for a Blueprint called 'first' ("blueprint create first; blueprint show --cfengine3 first")
first:
	$(CFSKETCH_DA) --install CFEngine::Blueprint
	$(CFSKETCH_DA) --uninstall first
	$(CFSKETCH_DA) --noforce --installsource=/home/tzz/source/blueprint/cfsketches.json --verbose --install first --activate first=/tmp/empty.json
	$(RUNNER)

stitch:
	$(CFSKETCH_DA) --install Data::Stitch --activate Data::Stitch=$(SOURCEDIR)/utilities/data_stitch/params/demo.json
	$(RUNNER)

splunk:
	$(CFSKETCH_DA) --install Applications::Splunk --activate Applications::Splunk=$(SOURCEDIR)/applications/splunk/params/demo.json
	$(RUNNER)

autobalance:
	$(CFSKETCH_DA) --install Cloud::Autobalance --activate Cloud::Autobalance=$(SOURCEDIR)/cloud/autobalance/params/demo.json
	$(RUNNER)

autobalance_vmware:
	$(CFSKETCH_DA) --install Cloud::Autobalance --activate Cloud::Autobalance=$(SOURCEDIR)/cloud/autobalance/params/demo_vmware.json
	$(RUNNER)

users_local:
	$(CFSKETCH_DA) --install Users::Local --activate Users::Local=$(SOURCEDIR)/system/users_local/params/demo.json
	$(RUNNER)

postfix:
	$(CFSKETCH_DA) --install Applications::Postfix::Client --activate Applications::Postfix::Client=$(SOURCEDIR)/applications/postfix/client/params/demo.json
	$(RUNNER)

nagios:
	$(CFSKETCH_DA) --install Applications::Nagios::NRPE --activate Applications::Nagios::NRPE=$(SOURCEDIR)/applications/nagios/nrpe/params/demo.json
	$(RUNNER)

php_fpm:
	$(CFSKETCH_DA) --install Applications::PHP_FPM --activate Applications::PHP_FPM=$(SOURCEDIR)/applications/php_fpm/params/demo.json
	$(RUNNER)

staging:
	$(CFSKETCH_DA) --install Utilities::Staging --activate Utilities::Staging=$(SOURCEDIR)/utilities/staging/params/demo.json
	$(RUNNER)

newrelic:
	$(CFSKETCH_DA) --install Applications::NewRelic --activate Applications::NewRelic=$(SOURCEDIR)/applications/newrelic/params/demo.json
	$(RUNNER)

apache:
	$(CFSKETCH_DA) --install Apache::Simple --activate Apache::Simple=$(SOURCEDIR)/web_servers/apache/params/demo_apache.json
	$(RUNNER)

uninstall_newrelic:
	$(CFSKETCH_DA) --uninstall Applications::NewRelic

demo_deploy:
	$(CFSKETCH_DA) --install Demo::SimpleApplication::Deploy --activate Demo::SimpleApplication::Deploy=$(SOURCEDIR)/demo/simpleapplication-deploy/params/demo.json
	$(RUNNER)

demo_s3deploy:
	$(CFSKETCH_DA) --install Demo::S3::Deploy --activate Demo::S3::Deploy=$(SOURCEDIR)/demo/s3_deploy/params/demo.json
	$(RUNNER)

data_triggers_github:
	$(CFSKETCH_DA) --install Data::Triggers::Github --activate Data::Triggers::Github=$(SOURCEDIR)/utilities/triggers_github/params/demo.json
	$(RUNNER)

data_triggers_jenkins:
	$(CFSKETCH_DA) --install Data::Triggers::Jenkins --activate Data::Triggers::Jenkins=$(SOURCEDIR)/utilities/triggers_jenkins/params/demo.json
	$(RUNNER)

run_withdata:
	$(CFSKETCH_DA) --install Run::WithData --activate Run::WithData=$(SOURCEDIR)/utilities/run_withdata/params/demo.json
	$(RUNNER)

run_once:
	$(CFSKETCH_DA) --install Run::Once --activate Run::Once=$(SOURCEDIR)/utilities/run_once/params/demo.json
	$(RUNNER)

dropdir:
	$(CFSKETCH_DA) --install Run::Dropdir --activate Run::Dropdir=$(SOURCEDIR)/utilities/dropdir/params/demo.json
	$(RUNNER)

stigs:
	$(CFSKETCH_DA) --install Security::STIG --activate Security::STIG=$(SOURCEDIR)/security/stigs/params/demo.json
	$(RUNNER)


sudoers:
	$(CFSKETCH_DA) --install System::Sudoers --activate System::Sudoers=$(SOURCEDIR)/system/sudoers/params/test.json
	(cd $(SOURCEDIR); make); $(PWD)/../cf-sketch/cf-sketch.pl --expert --apitest System::Sudoers
	$(RUNNER)

sudoers2:
	$(CFSKETCH_DA) --install System::Sudoers --activate System::Sudoers=$(SOURCEDIR)/system/sudoers/params/fnord.json
	$(RUNNER)

nologin:
	$(CFSKETCH_DA) --install Security::nologin --activate Security::nologin=$(SOURCEDIR)/security/nologin/params/present.json
	$(RUNNER)

nologin_off:
	$(CFSKETCH_DA) --install Security::nologin --activate Security::nologin=$(SOURCEDIR)/security/nologin/params/absent.json
	$(RUNNER)

files_existence:
	$(CFSKETCH_DA) --install Primitives::files_existence --activate Primitives::files_existence=$(SOURCEDIR)/primitives/file_existence/params/demo.json

roles:
	$(CFSKETCH_DA) --install Utilities::Roles --activate Utilities::Roles=$(SOURCEDIR)/utilities/roles/params/demo.json
	$(RUNNER)

users:
	$(CFSKETCH_DA) --install System::Users --activate System::Users=$(SOURCEDIR)/system/users/params/demo.json
	$(RUNNER)
