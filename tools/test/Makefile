PWD:=$(shell pwd)
SOURCEDIR:=$(PWD)/../../sketches

CFPATH:=$(dirname $(which cf-agent))

ifeq ($(CFPATH),)
  CFPATH:=/var/cfengine/bin
endif

# If $HOME/.cf-sketch-config.json exists, use it, otherwise use the defaults
ifeq ($(wildcard $(HOME)/.cf-sketch-config.json),)
  ifeq ($(LOGNAME),root)
    CFGFILE=$(PWD)/../cf-sketch/config-root.json
  else
    CFGFILE=$(PWD)/../cf-sketch/config.json
  endif
else
  CFGFILE=$(HOME)/.cf-sketch-config.json
endif

API_DIR:=~/.cfagent/inputs
RUNFILE:=~/.cfagent/inputs/standalone-cf-sketch-runfile.cf

CFAPI:=$(PWD)/../cf-sketch/cf-dc-api.pl $(CFGFILE)

ifeq ($(LOGNAME),root)
  RUNFILE:=/var/cfengine/inputs/standalone-cf-sketch-runfile.cf
  API_DIR:=/var/cfengine/inputs
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

API_RUNFILE:=$(API_DIR)/api-runfile.cf
API_SKETCHDIR:=$(API_DIR)/sketches

ifeq ($(VV),1)
  EXTRA:=--veryverbose
endif

ifeq ($(V),1)
  EXTRA:=--verbose
endif

ifneq ($(T),)
  EXTRA:= $(EXTRA) --test=$(T)
else
  EXTRA:= $(EXTRA) --test
endif

ifneq ($(A),)
  EXTRA:= $(EXTRA) --activated=$(A)
else
  EXTRA:= $(EXTRA) --activated
endif

ifneq ($(FILTER),)
  EXTRA:= $(EXTRA) --filter=$(FILTER)
endif

CFSKETCH:=(cd $(SOURCEDIR); make); $(PWD)/../cf-sketch/cf-sketch.pl --expert --installsource=$(SOURCEDIR)/cfsketches --cfpath=$(CFPATH) $(EXTRA) --force --standalone
CFSKETCH_DA:=rm $(RUNFILE); $(CFSKETCH) --install CFEngine::stdlib --deactivate-all --generate -v --force --standalonerunfile $(RUNFILE)
RUNNER:=$(CFPATH)/cf-agent -KI -f $(RUNFILE)

do:
	echo '{ dc_api_version: "0.0.1", request: {deactivate: true } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "production": { activated: true, test: false, verbose: true } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "Security::SSH", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" }, { sketch: "CFEngine::sketch_template", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" }, { sketch: "VCS::vcs_mirror", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "simple_sketch": { "CFEngine::sketch_template": { myboolean: true, myip: "10.0.1.0", mylist: [ 1, 2, 3 ], myarray: { a: 1, b: 3, c: 3 } } }, "simple_ssh": { "Security::SSH": { params: { Protocol : "2", X11Forwarding : "yes", PermitRootLogin : "yes" } } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { target: "$(API_SKETCHDIR)", environment: "production", params: [ "simple_ssh" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "CFEngine::sketch_template": { target: "$(API_SKETCHDIR)", environment: "production", params: [ "simple_sketch" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {regenerate: { } } }' | $(CFAPI)

api_test:
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "Applications::Memcached", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {test: ["Applications::Memcached"] } }' | $(CFAPI)

api_activate:
	@echo ...install CFEngine::sketch_template, deactivate all, activate just CFEngine::sketch_template with some metadata, then generate the runfile
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {deactivate: true } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "CFEngine::sketch_template": { target: "$(API_SKETCHDIR)", identifier: "my special identifier", metadata: { myvar: "myvalue" }, environment: "testing", params: [ "simple_sketch" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {regenerate: { } } }' | $(CFAPI)
	@echo ...deactivate my special identifier
	echo '{ dc_api_version: "0.0.1", request: {deactivate: "my special identifier" } }' | $(CFAPI)

api_validations:
	@echo ...define a choice-of validation with choice and derived
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { AB: { choice: [ "A", "B" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { C: { choice: [ "C" ] } } } }' | $(CFAPI)
	@echo ...define some basic validations
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { IPv4_local: { valid_ipv4: "10.0.0/24", invalid_ipv4: "10.0.0.1" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { IPv4: { valid_ipv4: "0.0.0.0/0" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { NONEMPTY_STRING: { valid_regex: "." } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { OCTAL: { valid_regex: "^[0-7]+$$" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { DIGITS: { valid_regex: "^[0-9]+$$" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { NUMBER: { derived: [ "DIGITS" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { 8BIT_NUMBER: { minimum_value: 0, maximum_value: 255 } } } }' | $(CFAPI)
	@echo ...define a derived validation
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { URL_HTTP_OR_FTP: { derived: [ "URL" ], valid_regex: "^(ftp|https?)://.+" } } } }' | $(CFAPI)
	@echo ...define some compound types
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { ARRAY_OF_NUMBERS_TO_URLS: { array_k: [ "NUMBER" ], array_v: [ "URL" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { LIST_OF_NUMBERS: { list: [ "NUMBER" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { LIST_OF_LIST_OF_NUMBERS: { list: [ "LIST_OF_NUMBERS" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { ARRAY_OF_NONEMPTY_STRINGS_TO_LIST_OF_LIST_OF_NUMBERS: { array_k: [ "NONEMPTY_STRING" ], array_v: [ "LIST_OF_LIST_OF_NUMBERS" ] } } } }' | $(CFAPI)

	echo '{ dc_api_version: "0.0.1", request: {define_validation: { UID: { derived: [ "NONEMPTY_STRING" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { GID: { derived: [ "NONEMPTY_STRING" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { MOG_SEQUENCE: { sequence: [ "OCTAL", "UID", "GID"  ] } } } }' | $(CFAPI)

	@echo ...define complicated URL regex
	echo '{ dc_api_version: "0.0.1", request: {define_validation: { URL: { valid_regex: "^[A-Za-z]{3,9}://.+" } } } }' | $(CFAPI)

api_validate:
	@echo ...now validate choices
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "AB", data: "A" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "AB", data: "" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "C", data: "C" } } }' | $(CFAPI)

	@echo ...now validate numeric data
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "8BIT_NUMBER", data: 100 } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "8BIT_NUMBER", data: 0 } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "8BIT_NUMBER", data: -1 } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "8BIT_NUMBER", data: 255 } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "8BIT_NUMBER", data: 256 } } }' | $(CFAPI)

	@echo ...now validate regex data
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "OCTAL", data: "100" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "OCTAL", data: "800" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "OCTAL", data: "" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "URL_HTTP_OR_FTP", data: "" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "URL_HTTP_OR_FTP", data: "http://github.com?p1=v1&p2=v2" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "URL_HTTP_OR_FTP", data: "file:///here" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "NONEMPTY_STRING", data: "hello" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "NONEMPTY_STRING", data: "" } } }' | $(CFAPI)

	@echo ...now validate IPs
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "IPv4_local", data: "10." } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "IPv4_local", data: "10.0.0.1" } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "IPv4_local", data: "10.0.0.99" } } }' | $(CFAPI)

	@echo ...try a list where a scalar should go
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "8BIT_NUMBER", data: [256] } } }' | $(CFAPI)

	@echo ...now a list of numbers
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "LIST_OF_NUMBERS", data: {"hello":256} } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "LIST_OF_NUMBERS", data: 256 } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "LIST_OF_NUMBERS", data: [] } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "LIST_OF_NUMBERS", data: [256] } } }' | $(CFAPI)

	@echo ...a sequence
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "MOG_SEQUENCE", data: {"hello":256} } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "MOG_SEQUENCE", data: 256 } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "MOG_SEQUENCE", data: [256] } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "MOG_SEQUENCE", data: [254, "you", "me"] } } }' | $(CFAPI)

	@echo ...a key-value array
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: {"hello":256} } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: 256 } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: [256] } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: { "20": "http://this.that", "30": "not a URL" } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: { "20": "http://this.that", "30": "http://this.that2" } } } }' | $(CFAPI)

api_environments:
	@echo ...show all environments
	echo '{ dc_api_version: "0.0.1", request: {environments:true} }' | $(CFAPI)
	@echo ...define testing run environment
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: true, test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...undefine testing run environment
	echo '{ dc_api_version: "0.0.1", request: {undefine_environment: [ "testing" ] } }' | $(CFAPI)
	@echo ...define testing run environment with include criteria... note that exclude criteria are ignored...
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: [], test: true, verbose: true } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: {}, test: true, verbose: true } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: {include:"x"}, test: true, verbose: true } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: {exclude:"x"}, test: true, verbose: true } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: {include:["x", "y.*"], exclude: ["b", "c"]}, test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...undefine testing run environment
	echo '{ dc_api_version: "0.0.1", request: {undefine_environment: [ "testing" ] } }' | $(CFAPI)

api_definitions:
	@echo ...show all definiions
	echo '{ dc_api_version: "0.0.1", request: {definitions:true} }' | $(CFAPI)
	@echo ...define some parameters
	echo '{ dc_api_version: "0.0.1", request: {define: { "vcs_base": { "VCS::vcs_mirror": { options: { parent_dir: { owner: { "function": "getenv", "args": ["LOGNAME", "128"] }, group: { "function": "getenv", "args": ["LOGNAME", "128"] }, perms: "755", ensure: true }, nowipe: true, vcs: { runas: { "function": "getenv", "args": ["LOGNAME", "128"] }, umask: "000" } } } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "git_mirror_core": { "VCS::vcs_mirror": { vcs: "/usr/bin/git", path: "/tmp/q/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git" }, "Security::SSH": { params: { "PermitRootLogin": "yes" } } } } } }' | $(CFAPI)
	@echo ...undefine a set of parameters
	echo '{ dc_api_version: "0.0.1", request: {undefine: ["vcs_base"] } }' | $(CFAPI)

api_search:
	@echo ...describe Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {describe:"Security::SSH"} }' | $(CFAPI)
	@echo ...list installed
	echo '{ dc_api_version: "0.0.1", request: {list: true } }' | $(CFAPI)
	@echo ...list installed matching Cloud or CFEngine
	echo '{ dc_api_version: "0.0.1", request: {list: [["name", "matches", "(Cloud|CFEngine|Security)"]] } }' | $(CFAPI)
	@echo ...list and describe any installed sketch matching ping
	echo '{ dc_api_version: "0.0.1", request: {describe: true, list: [["name", "matches", "ping"]] } }' | $(CFAPI)
	@echo ...dynamically generate a README for any installed sketch matching ping
	echo '{ dc_api_version: "0.0.1", request: {describe: "README", list: [["name", "matches", "ping"]] } }' | $(CFAPI)
	@echo ...search none
	echo '{ dc_api_version: "0.0.1", request: {search: false } }' | $(CFAPI)
	@echo ...search all available
	echo '{ dc_api_version: "0.0.1", request: {search: true } }' | $(CFAPI)
	@echo ...search all matching Cloud
	echo '{ dc_api_version: "0.0.1", request: {search: "Cloud" } }' | $(CFAPI)
	@echo ...search all matching Security
	echo '{ dc_api_version: "0.0.1", request: {search: ["Security"] } }' | $(CFAPI)
	@echo ...search available matching cloud or cfengine via regex
	echo '{ dc_api_version: "0.0.1", request: {search: [["name", "matches", "(Cloud|CFEngine)"]] } }' | $(CFAPI)
	@echo ...search available matching cloud or cfengine via data alternation
	echo '{ dc_api_version: "0.0.1", request: {search: [["name", "matches", "Cloud"], ["name", "matches", "CFEngine"]] } }' | $(CFAPI)
	@echo ...search available matching cloud in the tags
	echo '{ dc_api_version: "0.0.1", request: {search: [["tags", "matches", "cloud"]] } }' | $(CFAPI)

api:
	@echo '--- a full test of configuring VCS::vcs_mirror and reporting the directories it mirrors --'

	@echo ...define testing run environment
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: true, test: null, verbose: true } } } }' | $(CFAPI)

	@echo ...deactivate all activations
	echo '{ dc_api_version: "0.0.1", request: {deactivate: true } }' | $(CFAPI)

	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)

	@echo ...valid request to install CFEngine::sketch_template and VCS::vcs_mirror
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" }, { sketch: "VCS::vcs_mirror", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)

	@echo ...define CFEngine::sketch_template incomplete_sketch parameters
	echo '{ dc_api_version: "0.0.1", request: {define: { "incomplete_sketch": { "CFEngine::sketch_template": { myboolean: true, myarray: { a: 1, b: 3, c: 3 } } } } } }' | $(CFAPI)
	@echo define VCS::vcs_mirror parameters
	echo '{ dc_api_version: "0.0.1", request: {define: { "vcs_base": { "VCS::vcs_mirror": { options: { parent_dir: { owner: { "function": "getenv", "args": ["LOGNAME", "128"] }, group: { "function": "getenv", "args": ["LOGNAME", "128"] }, perms: "755", ensure: true }, nowipe: true, vcs: { runas: { "function": "getenv", "args": ["LOGNAME", "128"] }, umask: "000" } } } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "git_mirror_core": { "VCS::vcs_mirror": { vcs: "/usr/bin/git", path: "/tmp/q/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git" } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "svn_mirror_thrift": { "VCS::vcs_mirror": { vcs: "/usr/bin/svn", path: "/tmp/thrift-perl-lib", branch: "", origin: "http://svn.apache.org/repos/asf/thrift/attic/trunk/lib/perl", options: { parent_dir: { ensure: false } }  } } } } }' | $(CFAPI)

	@echo ...activate VCS::vcs_mirror with testing run environment and vcs_base+git_mirror_core and vcs_base+svn_mirror_thrift parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "vcs_base", "git_mirror_core" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "vcs_base", "svn_mirror_thrift" ] } } } }' | $(CFAPI)

	@echo ...compose some sketch values in other sketches: sketch composition
	echo '{ dc_api_version: "0.0.1", request: {decompose: "mirror_to_template_1" } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {compose: { mirror_to_template_1: { destination_sketch: "CFEngine::sketch_template", destination_list: "mylist", source_sketch: "VCS::vcs_mirror", source_scalar: "deploy_path" }, mirror_to_template_2: { destination_sketch: "CFEngine::sketch_template", destination_scalar: "myip", source_sketch: "VCS::vcs_mirror", source_scalar: "deploy_path" } } } }' | $(CFAPI)

	@echo ...activate CFEngine::sketch_template with testing run environment and incomplete_sketch parameters, with the previous compositions providing the glue
	echo '{ dc_api_version: "0.0.1", request: {activate: { "CFEngine::sketch_template": { compositions: [ "mirror_to_template_1", "mirror_to_template_2",], target: "$(API_SKETCHDIR)", environment: "testing", params: [ "incomplete_sketch" ] } } } }' | $(CFAPI)

	@echo ...generate the runfile
	echo '{ dc_api_version: "0.0.1", request: {regenerate: { } } }' | $(CFAPI)

api2:
	@echo '--- a full test of configuring Security::SSH, CFEngine::sketch_template, and VCS::vcs_mirror --'

	@echo ...define ANYTIME run environment
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "ANYTIME": { activated: "!nosuchclass", test: true, verbose: true } } } }' | $(CFAPI)
	@echo ...define testing run environment
	echo '{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: true, test: true, verbose: true } } } }' | $(CFAPI)

	@echo ...deactivate all activations
	echo '{ dc_api_version: "0.0.1", request: {deactivate: true } }' | $(CFAPI)

	@echo ...valid request to install Security::SSH, CFEngine::sketch_template, and VCS::vcs_mirror
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "Security::SSH", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" }, { sketch: "CFEngine::sketch_template", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" }, { sketch: "VCS::vcs_mirror", force: true, target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)

	@echo ...define Security::SSH simple_ssh and CFEngine::sketch_template simple_sketch parameters
	echo '{ dc_api_version: "0.0.1", request: {define: { "simple_sketch": { "CFEngine::sketch_template": { myboolean: true, myip: "10.0.1.0", mylist: [ 1, 2, 3 ], myarray: { a: 1, b: 3, c: 3 } } }, "simple_ssh": { "Security::SSH": { params: { Protocol : "2", X11Forwarding : "yes", PermitRootLogin : "yes" } } } } } }' | $(CFAPI)
	@echo define VCS::vcs_mirror parameters
	echo '{ dc_api_version: "0.0.1", request: {define: { "vcs_base": { "VCS::vcs_mirror": { options: { parent_dir: { owner: { "function": "getenv", "args": ["LOGNAME", "128"] }, group: { "function": "getenv", "args": ["LOGNAME", "128"] }, perms: "755", ensure: true }, nowipe: true, vcs: { runas: { "function": "getenv", "args": ["LOGNAME", "128"] }, umask: "000" } } } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "git_mirror_core": { "VCS::vcs_mirror": { vcs: "/usr/bin/git", path: "/tmp/q/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git" } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "svn_mirror_thrift": { "VCS::vcs_mirror": { vcs: "/usr/bin/svn", path: "/tmp/thrift-perl-lib", branch: "", origin: "http://svn.apache.org/repos/asf/thrift/attic/trunk/lib/perl", options: { parent_dir: { ensure: false } }  } } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {define: { "git_invalid": { "VCS::vcs_mirror": { path: "/tmp/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git", options: { umask: "000" }, vcs: "/no/such/versioning_system" } } } } }' | $(CFAPI)

	@echo ...activate Security::SSH with ANYTIME run environment and simple_ssh parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { target: "$(API_SKETCHDIR)", environment: "ANYTIME", params: [ "simple_ssh" ] } } } }' | $(CFAPI)
	@echo ...activate CFEngine::sketch_template with testing run environment and simple_sketch parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "CFEngine::sketch_template": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "simple_sketch" ] } } } }' | $(CFAPI)
	@echo ...activate VCS::vcs_mirror with testing run environment and vcs_base+git_mirror_core and vcs_base+svn_mirror_thrift parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "vcs_base", "git_mirror_core" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "vcs_base", "svn_mirror_thrift" ] } } } }' | $(CFAPI)
	@echo ...activate VCS::vcs_mirror with testing run environment and git_invalid parameters
	echo '{ dc_api_version: "0.0.1", request: {activate: { "VCS::vcs_mirror": { target: "$(API_SKETCHDIR)", environment: "testing", params: [ "git_invalid" ] } } } }' | $(CFAPI)

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
	@echo ...dynamically generate a README for any installed sketch matching ping
	echo '{ dc_api_version: "0.0.1", request: {describe: "README", list: [["name", "matches", "ping"]] } }' | $(CFAPI)
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
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	@echo ...invalid request to install CFEngine::sketch_template: bad version
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", version: "-1", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to install CFEngine::sketch_template
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to reinstall CFEngine::sketch_template
	echo '{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } ] } }' | $(CFAPI)
	@echo ...invalid request to uninstall CFEngine::sketch_template: missing target
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::sketch_template" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::sketch_template
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::sketch_template", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to install Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {install: { sketch: "Security::SSH", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } } }' | $(CFAPI)
	@echo ...valid request to uninstall Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "Security::SSH", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)

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
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "Security::SSH", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)

	@echo ...valid request to install Security::SSH
	echo '{ dc_api_version: "0.0.1", request: {install: { sketch: "Security::SSH", target: "$(API_SKETCHDIR)", source: "$(SOURCEDIR)" } } }' | $(CFAPI)
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
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { bundle: "nosuchbundle", target: "$(API_SKETCHDIR)", environment: "ANYTIME", params: [ "simple_ssh" ] } } } }' | $(CFAPI)
	echo '{ dc_api_version: "0.0.1", request: {activate: { "Security::SSH": { target: "$(API_SKETCHDIR)", environment: "ANYTIME", params: [ "simple_ssh" ] } } } }' | $(CFAPI)

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
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "Security::SSH", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)
	@echo ...valid request to uninstall CFEngine::stdlib
	echo '{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "$(API_SKETCHDIR)" } ] } }' | $(CFAPI)

run:
	$(RUNNER)

generate:
	$(CFSKETCH) --generate --runfile $(RUNFILE)

list:
	$(CFSKETCH) --list

search:
	$(CFSKETCH) --search

regenerate_readme:
	$(CFSKETCH) --make_readme

test:
	$(CFSKETCH) --install $(SKETCH) --apitest $(SKETCH) --noignore -v

testinstalled:
	$(CFSKETCH) --apitest $(SKETCH) --noignore -v

testallinstalled:
	$(CFSKETCH) --apitest 1 --noignore -v

testcoverage:
	$(CFSKETCH) --apitest 1 --coverage --noignore -v

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

aws_ec2:
	$(CFSKETCH_DA) --install Cloud::Services::AWS::EC2 --activate Cloud::Services::AWS::EC2=$(SOURCEDIR)/cloud/aws_ec2/params/demo.json
	$(RUNNER)

aws_s3:
	$(CFSKETCH_DA) --install Cloud::Services::AWS::S3 --activate Cloud::Services::AWS::S3=$(SOURCEDIR)/cloud/aws_s3/params/demo.json
	$(RUNNER)

aws_sdb:
	$(CFSKETCH_DA) --install Cloud::Services::AWS::SDB --activate Cloud::Services::AWS::SDB=$(SOURCEDIR)/cloud/aws_sdb/params/demo.json
	$(RUNNER)

vcli:
	@echo NOT IMPLEMENTED

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

postgresql_client:
	$(CFSKETCH_DA) --install Database::Install::PostgreSQL --activate Database::Install::PostgreSQL=$(SOURCEDIR)/databases/postgresql_install/params/demo_client.json
	$(RUNNER)

postgresql_server:
	$(CFSKETCH_DA) --install Database::Install::PostgreSQL --activate Database::Install::PostgreSQL=$(SOURCEDIR)/databases/postgresql_install/params/demo_server.json
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
	$(CFSKETCH_DA) --install Packages::Debian::single --activate Packages::Debian::single=$(SOURCEDIR)/package_management/debian/single/params/demo.json
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
	$(CFSKETCH_DA) --install System::Syslog --activate System::Syslog=$(SOURCEDIR)/system/syslog/params/demo.json
	$(RUNNER)

sudoers:
	$(CFSKETCH_DA) --install System::Sudoers --activate System::Sudoers=$(SOURCEDIR)/system/sudoers/params/demo.json
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

packages_installed:
	$(CFSKETCH_DA) --install Packages::installed --activate Packages::installed=$(SOURCEDIR)/package_management/packages_installed/params/demo.json
	$(RUNNER)
