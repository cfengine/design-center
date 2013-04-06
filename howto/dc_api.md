# The Design Center API

## Design Center HOWTO series

### Author: Ted Zlatanov <tzz@lifelogs.com>

### Version: 0.0.1-1

### API General Information

The Design Center API (DC API or just API henceforth) is a simple JSON-based
protocol for communicating with the Design Center backend.  The backend may be
running locally or remotely; the API makes no assumptions about the transport
channel and is entirely a line-based text protocol consisting of *one* JSON line
each way.

The API client makes a request and gets a response over the same channel.
Again, the request and the response can only be a single line of text, ended by
the transport channel's standard line-ending sequence, e.g. CRLF for HTTP.  JSON
escapes such sequences so they should not happen anywhere in the payloads.

API requests have the following general structure:

```json
{ dc_api_version: "0.0.1", request: { ...commands... } }
```

The version is strictly semantically versioned as *major.minor.patch*.  It must
match exactly, so you can't have a _0.0.1_ client talking to a _0.0.2_ server
for instance (the client has to say "0.0.2" to be usable).  We expect backwards
compatibility, this is just a way to avoid misunderstandings.

#### NOTE: Generally, only *one* command may be specified per request.

API responses look like this:

```json
{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{}, "log":[], "tags": {}, "data":{ ...response data... }}}
```

The top key can be one of the following:

* `api_ok`: the command was processed correctly and the response is enclosed as
  valid JSON (note that this doesn't mean the response indicates success!!!)
  
* `api_error`: the command was not processed correctly and the response may not
  be valid JSON at all.  It may be good JSON and even contain keys like `api_ok`
  promises, e.g. `warnings` or `success`, but you can't rely on that.

The API client may wish to replace unparseable data with
`{api_error: "BAD JSON (escaped data here)"}` or something similar to make the
response handler simpler.

Inside the API response, under the `api_ok` key, you can expect to find the following:

* `success`: indicates, generally speaking, that the command succeeded or
  failed.  Any complex commands can fail in subtle ways, but the API will do its
  best to make this a good indicator.
  
* `errors` and `warnings`: lists of strings that log errors and warnings for the
  command.
  
* `error_tags`: key-value array of tag strings assigned to the error messages.
  This lets the client tell what stages or areas of the command triggered the
  errors.
  
* `log`: list of general message strings.  This is optional and purely informational.
  
* `tags`: key-value array of tag strings assigned to the response, not
  associated with errors.  This lets the client tell what stages or areas of the
  command triggered messages or warnings, or more generally what stages or areas
  of the command were executed.  This is optional and purely informational.

* `data`: the meat of the response plate, if you will.  This key contains all
  the response data that the API command generated.  Each command has different
  return data so the specifics are listed per command.
  
### API Commands

The API commands and their data responses are listed below.  Generally they are
exclusive of each other, and the order below is the order in which they are
answered.  Thus, for instance, a request that issues both `list` and `search`
will get just the `list` results.

Many commands take *terms*.  *Terms* are one of the following:

* a string (matches any field)
* a list of strings (any of them may match any field)
* a list of lists, with each one in the following format: either
  `[FIELD, "matches", REGEX]` or `[FIELD, "equals", STRING]` or
  `[[FIELD1, FIELD2,...], "matches", STRING]`.

#### `list`

The `list` command lists *installed* sketches.

Here are examples of three `list` commands.  The first one lists everything installed.

```json
{ dc_api_version: "0.0.1", request: {list: true } }
    
{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"list":{"/home/tzz/.cfagent/inputs/sketches":{"CFEngine::dclib::3.5.0":"CFEngine::dclib::3.5.0","CFEngine::dclib":"CFEngine::dclib","CFEngine::sketch_template":"CFEngine::sketch_template","VCS::vcs_mirror":"VCS::vcs_mirror","Security::SSH":"Security::SSH","Utilities::ping_report":"Utilities::ping_report","Monitoring::SNMP::Walk":"Monitoring::SNMP::Walk","Data::Classes":"Data::Classes","CFEngine::stdlib":"CFEngine::stdlib","Utilities::ipverify":"Utilities::ipverify"}}},"log":[],"tags":{}}}
```

Note the top-level key under `data` is the name of the repository, which is
always a local directory.

The next one takes *terms* and lists all the sketches whose name satisfies the
*terms*.
    
```json
{ dc_api_version: "0.0.1", request: {list: [["name", "matches", "(Cloud|CFEngine|Security)"]] } }

{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"list":{"/home/tzz/.cfagent/inputs/sketches":{"Security::SSH":"Security::SSH","CFEngine::dclib::3.5.0":"CFEngine::dclib::3.5.0","CFEngine::dclib":"CFEngine::dclib","CFEngine::sketch_template":"CFEngine::sketch_template","CFEngine::stdlib":"CFEngine::stdlib"}}},"log":[],"tags":{}}}
```

##### option: `describe`

When `describe` is given as a top-level option with a value of `true`, as in the
example below, the returned data is the contents of `sketch.json`.

```json
{ dc_api_version: "0.0.1", request: {describe: true, list: [["name", "matches", "ping"]] } }

{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"list":{"/home/tzz/.cfagent/inputs/sketches":{"Utilities::ping_report":{"namespace":"cfdc_ping","manifest":{"changelog":{"comment":"changelog"},"test.cf":{"comment":"Test Policy"},"README.md":{"documentation":true},"params/example.json":{"comment":"Example parameters to report on a few hosts connectivity."},"main.cf":{"desc":"main file"}},"interface":["main.cf"],"metadata":{"authors":["Nick Anderson <nick@cmdln.org>","Ted Zlatanov <tzz@lifelogs.com>"],"version":1.2,"name":"Utilities::ping_report","license":"MIT","description":"Report on pingability of hosts","tags":["cfdc"],"depends":{"cfengine":{"version":"3.4.0"},"CFEngine::dclib":{},"os":["linux"],"CFEngine::stdlib":{"version":105}}},"entry_point":null,"api":{"ping":[{"name":"runenv","type":"environment"},{"name":"metadata","type":"metadata"},{"name":"hosts","type":"list"},{"name":"count","type":"string"},{"name":"reached","type":"return"},{"name":"not_reached","type":"return"}]}}}}},"log":[],"tags":{}}}
```

When `describe` is given as a top-level option with a value of `README`, as in
the example below, the returned data is actually the sketch's auto-generated
`README.md` file (which comes from `sketch.json`).  The `tools/test/Makefile`
testing Makefile has a convenience `regenerate_readme` target to do this for all
the DC sketches.

```json
{ dc_api_version: "0.0.1", request: {describe: "README", list: [["name", "matches", "ping"]] } }

{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"list":{"/home/tzz/.cfagent/inputs/sketches":{"Utilities::ping_report":["/home/tzz/.cfagent/inputs/sketches/utilities/ping_report","# Utilities::ping_report version 1.2\n\nLicense: MIT\nTags: cfdc\nAuthors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>\n\n## Description\nReport on pingability of hosts\n\n## Dependencies\nCFEngine::dclib, CFEngine::stdlib\n\n## API\n### bundle: ping\n* parameter _environment_ *runenv* (default: none, description: none)\n\n* parameter _metadata_ *metadata* (default: none, description: none)\n\n* parameter _list_ *hosts* (default: none, description: none)\n\n* parameter _string_ *count* (default: none, description: none)\n\n* returns _return_ *reached* (default: none, description: none)\n\n* returns _return_ *not_reached* (default: none, description: none)\n\n\n## SAMPLE USAGE\nSee `test.cf` or the example parameters provided\n\n"]}}},"log":[],"tags":{}}}
```

#### `search`

The `search` command works exactly like `list` above, except that the candidate
list contains all available sketches (from `recognized_sources`), not just the
installed sketches.

##### option: `describe`

The `describe` option to `search` works exactly like it does for `list` above.

#### `describe`

The `describe` command gives the contents of `sketch.json` for the matching
installed sketches by name.

```json
{ dc_api_version: "0.0.1", request: {describe:"Security::SSH"} }
    
{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"describe":{"/home/tzz/.cfagent/inputs/sketches":{"Security::SSH":[{"namespace":"cfdc_sshd","manifest":{"ssh.cf":{"desc":"main file"},"README.md":{"documentation":true},"params/simple.json":{}},"interface":["ssh.cf"],"metadata":{"authors":["Diego Zamboni <diego.zamboni@cfengine.com>","Ted Zlatanov <tzz@lifelogs.com>"],"version":1.1,"name":"Security::SSH","license":"MIT","description":"Configure and enable sshd","tags":["cfdc"],"depends":{"cfengine":{"version":"3.4.0"},"CFEngine::dclib":{"version":"1.0.0"},"CFEngine::stdlib":{"version":105}}},"api":{"sshd":[{"name":"runenv","type":"environment"},{"name":"metadata","type":"metadata"},{"name":"params","type":"array"}]}}]},"/home/tzz/source/design-center/sketches":{"Security::SSH":[{"namespace":"cfdc_sshd","manifest":{"ssh.cf":{"desc":"main file"},"README.md":{"documentation":true},"params/simple.json":{}},"interface":["ssh.cf"],"metadata":{"authors":["Diego Zamboni <diego.zamboni@cfengine.com>","Ted Zlatanov <tzz@lifelogs.com>"],"version":1.1,"name":"Security::SSH","license":"MIT","description":"Configure and enable sshd","tags":["cfdc"],"depends":{"cfengine":{"version":"3.4.0"},"CFEngine::dclib":{"version":"1.0.0"},"CFEngine::stdlib":{"version":105}}},"api":{"sshd":[{"name":"runenv","type":"environment"},{"name":"metadata","type":"metadata"},{"name":"params","type":"array"}]}}]}}},"log":[],"tags":{}}}
```

#### `install`

The `install` command installs any number of sketches.  The data provides is a
list of key-value arrays with keys:

* `force`: boolean, false by default.  Whether any existing installations of the
  sketch should be respected or overwritten.  Also asks the API to ignore OS and
  CFEngine version dependencies.

* `sketch`: the sketch name.

* `target`: the sketch install directory.  Must be in the API's `repolist`.

* `source`: the sketch source repository.  Must be in the API's `recognized_sources`.

```json
{ dc_api_version: "0.0.1", request: {install: [ { sketch: "CFEngine::sketch_template", force: true, target: "~/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/tools/test/../../sketches" }, { sketch: "VCS::vcs_mirror", force: true, target: "~/.cfagent/inputs/sketches", source: "/home/tzz/source/design-center/tools/test/../../sketches" } ] } }
```

The return data is a key-value array as follows, describing the installation details.

```json
{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"VCS::vcs_mirror":{"params/thrift-lib-perl.json":"/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/params/thrift-lib-perl.json","README.md":"/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/README.md","params/cfengine-core.json":"/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/params/cfengine-core.json","params/cfengine-copbl.json":"/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/params/cfengine-copbl.json","main.cf":"/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/main.cf","params/cfengine-core-runas-tzz.json":"/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/params/cfengine-core-runas-tzz.json"},"install":{"~/.cfagent/inputs/sketches":{"VCS::vcs_mirror":1,"CFEngine::sketch_template":1}},"inventory_save":1,"CFEngine::sketch_template":{"test.cf":"/home/tzz/.cfagent/inputs/sketches/sketch_template/test.cf","scripts/sample.sh":"/home/tzz/.cfagent/inputs/sketches/sketch_template/scripts/sample.sh","params/demo.json":"/home/tzz/.cfagent/inputs/sketches/sketch_template/params/demo.json","README.md":"/home/tzz/.cfagent/inputs/sketches/sketch_template/README.md","modules/mymodule":"/home/tzz/.cfagent/inputs/sketches/sketch_template/modules/mymodule","main.cf":"/home/tzz/.cfagent/inputs/sketches/sketch_template/main.cf"}},"log":[],"tags":{"VCS::vcs_mirror":1,"installation":7,"CFEngine::sketch_template":1}}}
```

#### `uninstall`

The `uninstall` command simply deletes the top-level sketch directory and
everything under it.  It takes a list of key-value arrays with keys:

* `sketch`: the sketch name.

* `target`: the sketch install directory we want to clean.  Must be in the API's `repolist`.

```json
{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "~/.cfagent/inputs/sketches" } ] } }

{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"inventory_save":1,"uninstall":{"~/.cfagent/inputs/sketches":{"CFEngine::stdlib":1}}},"log":[],"tags":{"uninstallation":1,"CFEngine::stdlib":1}}}
```

The `inventory_save` key in the return indicates whether the inventory (`cfsketches.json`) was written successfully.

#### `compositions`

The `compositions` command lists the defined compositions.

```json
{ dc_api_version: "0.0.1", request: {compositions: true} }

{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"compositions":{"mirror_to_template_2":{"destination_sketch":"CFEngine::sketch_template","source_scalar":"deploy_path","source_sketch":"VCS::vcs_mirror","destination_scalar":"myip"},"mirror_to_template_1":{"destination_sketch":"CFEngine::sketch_template","source_scalar":"deploy_path","source_sketch":"VCS::vcs_mirror","destination_list":"mylist"}}},"log":[],"tags":{}}}
```

#### `compose`

The `compose` command defines a composition.  It returns the same data as `compositions`.

```json
{ dc_api_version: "0.0.1", request: {compose: { mirror_to_template_1: { destination_sketch: "CFEngine::sketch_template", destination_list: "mylist", source_sketch: "VCS::vcs_mirror", source_scalar: "deploy_path" }, mirror_to_template_2: { destination_sketch: "CFEngine::sketch_template", destination_scalar: "myip", source_sketch: "VCS::vcs_mirror", source_scalar: "deploy_path" } } } }
    
{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"compositions":{"mirror_to_template_2":{"destination_sketch":"CFEngine::sketch_template","source_scalar":"deploy_path","source_sketch":"VCS::vcs_mirror","destination_scalar":"myip"},"mirror_to_template_1":{"destination_sketch":"CFEngine::sketch_template","source_scalar":"deploy_path","source_sketch":"VCS::vcs_mirror","destination_list":"mylist"}}},"log":[],"tags":{"compose":1}}}
```

#### `decompose`

The `decompose` command undefines a composition by name.  It returns the same data as `compositions`.

```json
{ dc_api_version: "0.0.1", request: {decompose: "mirror_to_template_1" } }

{"api_ok":{"warnings":[],"success":true,"errors":[],"error_tags":{},"data":{"compositions":{"destination_sketch":"CFEngine::sketch_template","source_scalar":"deploy_path","source_sketch":"VCS::vcs_mirror","destination_list":"mylist"}},"log":[],"tags":{"compose":1}}}
```

#### `activations`

The `activations` command lists the defined activations.

#### `activate`

The `activate` command defines a new activation of a sketch.

##### option: `compose`

#### `deactivate`

The `deactivate` command removes a sketch activation.

#### `definitions`

The `definitions` command lists the parameter definitions.

#### `define`

The `define` command creates a parameter definition.

#### `undefine`

The `undefine` command removes a parameter definition by name.

#### `environments`

The `environments` command lists the run environments.

#### `define_environment`

The `define_environemnt` command defines a run environment.

#### `undefine_environment`

The `undefine_environemnt` command removes a run environment.

#### `validations`

The `validations` command lists the data validations.

#### `define_validation`

The `define_validation` command defines a data validation.

#### `undefine_validation`

The `undefine_validation` command removes a data validation.

#### `regenerate`

The `regenerate` command writes the API runfile (as specified in the API
configuration) from all the known activations, compositions, run environments,
parameter definitions, and data validations.

### API CLI Interface and config.json

From the command line, you can run `cd tools/cf-sketch; ./cf-dc-api.pl
config.json` where `config.json` contains the necessary configuration for the
API:

#### `log`

Either `STDOUT` or `STDERR` or a file name.

#### `log_level`

1-5 currently.  4 or 5 for debugging; 1 or 2 for normal usage.

3 is for people who can't make up their mind.

#### `repolist`

A list of local directories where sketches may be installed.

#### `recognized_sources`

A list of DC repositories where sketches may be installed FROM.  There can be
local directories or URLs.

#### `runfile`

A key-value array with keys `location` for the place where the runfile is
written; `standalone` for the runfile standalone (when false, this setting makes
the runfile suitable for inclusion in the main `promises.cf`); `relocate_path`
for what to add to all inputs.

#### `vardata`

The file location where the API will record all data.

#### Full `config.json` example

```json
{
 log: "STDERR",
 log_level: 4,
 repolist: [ "~/.cfagent/inputs/sketches" ],
 recognized_sources: [ "~/source/design-center/sketches" ],
 runfile: { location: "~/.cfagent/inputs/api-runfile.cf", standalone: true, relocate_path: "sketches" },
 vardata: "~/.cfagent/vardata.conf",
}
```
