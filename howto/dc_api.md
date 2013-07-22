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
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "log": [],
        "tags": {},
        "data": {...response data...
        }
    }
}
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
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "list": {
                "/home/tzz/.cfagent/inputs/sketches": {
                    "CFEngine::dclib::3.5.0": "CFEngine::dclib::3.5.0",
                    "CFEngine::dclib": "CFEngine::dclib",
                    "CFEngine::sketch_template": "CFEngine::sketch_template",
                    "VCS::vcs_mirror": "VCS::vcs_mirror",
                    "Security::SSH": "Security::SSH",
                    "Utilities::ping_report": "Utilities::ping_report",
                    "Monitoring::SNMP::Walk": "Monitoring::SNMP::Walk",
                    "Data::Classes": "Data::Classes",
                    "CFEngine::stdlib": "CFEngine::stdlib",
                    "Utilities::ipverify": "Utilities::ipverify"
                }
            }
        },
        "log": [],
        "tags": {}
    }
}
```

Note the top-level key under `data` is the name of the repository, which is
always a local directory.

The next one takes *terms* and lists all the sketches whose name satisfies the
*terms*.
    
```json
{ dc_api_version: "0.0.1", request: {list: [["name", "matches", "(Cloud|CFEngine|Security)"]] } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "list": {
                "/home/tzz/.cfagent/inputs/sketches": {
                    "Security::SSH": "Security::SSH",
                    "CFEngine::dclib::3.5.0": "CFEngine::dclib::3.5.0",
                    "CFEngine::dclib": "CFEngine::dclib",
                    "CFEngine::sketch_template": "CFEngine::sketch_template",
                    "CFEngine::stdlib": "CFEngine::stdlib"
                }
            }
        },
        "log": [],
        "tags": {}
    }
}
```

##### option: `describe`

When `describe` is given as a top-level option with a value of `true`, as in the
example below, the returned data is the contents of `sketch.json`.

```json
{ dc_api_version: "0.0.1", request: {describe: true, list: [["name", "matches", "ping"]] } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "list": {
                "/home/tzz/.cfagent/inputs/sketches": {
                    "Utilities::ping_report": {
                        "namespace": "cfdc_ping",
                        "manifest": {
                            "changelog": {
                                "comment": "changelog"
                            },
                            "test.cf": {
                                "comment": "Test Policy"
                            },
                            "README.md": {
                                "documentation": true
                            },
                            "params/example.json": {
                                "comment": "Example parameters to report on a few hosts connectivity."
                            },
                            "main.cf": {
                                "desc": "main file"
                            }
                        },
                        "interface": ["main.cf"],
                        "metadata": {
                            "authors": ["Nick Anderson <nick@cmdln.org>", "Ted Zlatanov <tzz@lifelogs.com>"],
                            "version": 1.2,
                            "name": "Utilities::ping_report",
                            "license": "MIT",
                            "description": "Report on pingability of hosts",
                            "tags": ["cfdc"],
                            "depends": {
                                "cfengine": {
                                    "version": "3.4.0"
                                },
                                "CFEngine::dclib": {},
                                "os": ["linux"],
                                "CFEngine::stdlib": {
                                    "version": 105
                                }
                            }
                        },
                        "entry_point": null,
                        "api": {
                            "ping": [{
                                "name": "runenv",
                                "type": "environment"
                            },
                            {
                                "name": "metadata",
                                "type": "metadata"
                            },
                            {
                                "name": "hosts",
                                "type": "list"
                            },
                            {
                                "name": "count",
                                "type": "string"
                            },
                            {
                                "name": "reached",
                                "type": "return"
                            },
                            {
                                "name": "not_reached",
                                "type": "return"
                            }]
                        }
                    }
                }
            }
        },
        "log": [],
        "tags": {}
    }
}
```

When `describe` is given as a top-level option with a value of `README`, as in
the example below, the returned data is actually the sketch's auto-generated
`README.md` file (which comes from `sketch.json`).  The `tools/test/Makefile`
testing Makefile has a convenience `regenerate_readme` target to do this for all
the DC sketches.

```json
{ dc_api_version: "0.0.1", request: {describe: "README", list: [["name", "matches", "ping"]] } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "list": {
                "/home/tzz/.cfagent/inputs/sketches": {
                    "Utilities::ping_report": ["/home/tzz/.cfagent/inputs/sketches/utilities/ping_report", "# Utilities::ping_report version 1.2\n\nLicense: MIT\nTags: cfdc\nAuthors: Nick Anderson <nick@cmdln.org>, Ted Zlatanov <tzz@lifelogs.com>\n\n## Description\nReport on pingability of hosts\n\n## Dependencies\nCFEngine::dclib, CFEngine::stdlib\n\n## API\n### bundle: ping\n* parameter _environment_ *runenv* (default: none, description: none)\n\n* parameter _metadata_ *metadata* (default: none, description: none)\n\n* parameter _list_ *hosts* (default: none, description: none)\n\n* parameter _string_ *count* (default: none, description: none)\n\n* returns _return_ *reached* (default: none, description: none)\n\n* returns _return_ *not_reached* (default: none, description: none)\n\n\n## SAMPLE USAGE\nSee `test.cf` or the example parameters provided\n\n"]
                }
            }
        },
        "log": [],
        "tags": {}
    }
}
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
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "describe": {
                "/home/tzz/.cfagent/inputs/sketches": {
                    "Security::SSH": [{
                        "namespace": "cfdc_sshd",
                        "manifest": {
                            "ssh.cf": {
                                "desc": "main file"
                            },
                            "README.md": {
                                "documentation": true
                            },
                            "params/simple.json": {}
                        },
                        "interface": ["ssh.cf"],
                        "metadata": {
                            "authors": ["Diego Zamboni <diego.zamboni@cfengine.com>", "Ted Zlatanov <tzz@lifelogs.com>"],
                            "version": 1.1,
                            "name": "Security::SSH",
                            "license": "MIT",
                            "description": "Configure and enable sshd",
                            "tags": ["cfdc"],
                            "depends": {
                                "cfengine": {
                                    "version": "3.4.0"
                                },
                                "CFEngine::dclib": {
                                    "version": "1.0.0"
                                },
                                "CFEngine::stdlib": {
                                    "version": 105
                                }
                            }
                        },
                        "api": {
                            "sshd": [{
                                "name": "runenv",
                                "type": "environment"
                            },
                            {
                                "name": "metadata",
                                "type": "metadata"
                            },
                            {
                                "name": "params",
                                "type": "array"
                            }]
                        }
                    }]
                },
                "/home/tzz/source/design-center/sketches": {
                    "Security::SSH": [{
                        "namespace": "cfdc_sshd",
                        "manifest": {
                            "ssh.cf": {
                                "desc": "main file"
                            },
                            "README.md": {
                                "documentation": true
                            },
                            "params/simple.json": {}
                        },
                        "interface": ["ssh.cf"],
                        "metadata": {
                            "authors": ["Diego Zamboni <diego.zamboni@cfengine.com>", "Ted Zlatanov <tzz@lifelogs.com>"],
                            "version": 1.1,
                            "name": "Security::SSH",
                            "license": "MIT",
                            "description": "Configure and enable sshd",
                            "tags": ["cfdc"],
                            "depends": {
                                "cfengine": {
                                    "version": "3.4.0"
                                },
                                "CFEngine::dclib": {
                                    "version": "1.0.0"
                                },
                                "CFEngine::stdlib": {
                                    "version": 105
                                }
                            }
                        },
                        "api": {
                            "sshd": [{
                                "name": "runenv",
                                "type": "environment"
                            },
                            {
                                "name": "metadata",
                                "type": "metadata"
                            },
                            {
                                "name": "params",
                                "type": "array"
                            }]
                        }
                    }]
                }
            }
        },
        "log": [],
        "tags": {}
    }
}
```

#### `install`

The `install` command installs any number of sketches.  The data provides is a
list of key-value arrays with keys:

* `force`: boolean, false by default.  Whether any existing installations of the
  sketch should be respected or overwritten.  Also asks the API to ignore OS and
  CFEngine version dependencies.

* `sketch`: the sketch name.

* `target`: the sketch install directory.  Must be in the API's `repolist`.  Optional; when not given, the first element of the `repolist` will be used.

* `source`: the sketch source repository.  Must be in the API's `recognized_sources`.  Optional; when not given, every element of the `recognized_sources` will be tried.  Can be a string or an array of strings.

```json
{
    dc_api_version: "0.0.1",
    request: {
        install: [{
            sketch: "CFEngine::sketch_template",
            force: true,
        },
        {
            sketch: "VCS::vcs_mirror",
            force: true,
            target: "~/.cfagent/inputs/sketches",
            source: "/home/tzz/source/design-center/tools/test/../../sketches"
        }]
    }
}
```

The return data is a key-value array as follows, describing the installation details.

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "VCS::vcs_mirror": {
                "params/thrift-lib-perl.json": "/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/params/thrift-lib-perl.json",
                "README.md": "/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/README.md",
                "params/cfengine-core.json": "/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/params/cfengine-core.json",
                "params/cfengine-copbl.json": "/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/params/cfengine-copbl.json",
                "main.cf": "/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/main.cf",
                "params/cfengine-core-runas-tzz.json": "/home/tzz/.cfagent/inputs/sketches/utilities/vcs_mirror/params/cfengine-core-runas-tzz.json"
            },
            "install": {
                "~/.cfagent/inputs/sketches": {
                    "VCS::vcs_mirror": 1,
                    "CFEngine::sketch_template": 1
                }
            },
            "inventory_save": 1,
            "CFEngine::sketch_template": {
                "test.cf": "/home/tzz/.cfagent/inputs/sketches/sketch_template/test.cf",
                "scripts/sample.sh": "/home/tzz/.cfagent/inputs/sketches/sketch_template/scripts/sample.sh",
                "params/demo.json": "/home/tzz/.cfagent/inputs/sketches/sketch_template/params/demo.json",
                "README.md": "/home/tzz/.cfagent/inputs/sketches/sketch_template/README.md",
                "modules/mymodule": "/home/tzz/.cfagent/inputs/sketches/sketch_template/modules/mymodule",
                "main.cf": "/home/tzz/.cfagent/inputs/sketches/sketch_template/main.cf"
            }
        },
        "log": [],
        "tags": {
            "VCS::vcs_mirror": 1,
            "installation": 7,
            "CFEngine::sketch_template": 1
        }
    }
}
```

#### `uninstall`

The `uninstall` command simply deletes the top-level sketch directory and
everything under it.  It takes a list of key-value arrays with keys:

* `sketch`: the sketch name.

* `target`: the sketch install directory we want to clean.  Must be in the API's `repolist`.

```json
{ dc_api_version: "0.0.1", request: {uninstall: [ { sketch: "CFEngine::stdlib", target: "~/.cfagent/inputs/sketches" } ] } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "inventory_save": 1,
            "uninstall": {
                "~/.cfagent/inputs/sketches": {
                    "CFEngine::stdlib": 1
                }
            }
        },
        "log": [],
        "tags": {
            "uninstallation": 1,
            "CFEngine::stdlib": 1
        }
    }
}
```

The `inventory_save` key in the return indicates whether the inventory (`cfsketches.json`) was written successfully.

#### `compositions`

The `compositions` command lists the defined compositions.

```json
{ dc_api_version: "0.0.1", request: {compositions: true} }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "compositions": {
                "mirror_to_template_2": {
                    "destination_sketch": "CFEngine::sketch_template",
                    "source_scalar": "deploy_path",
                    "source_sketch": "VCS::vcs_mirror",
                    "destination_scalar": "myip"
                },
                "mirror_to_template_1": {
                    "destination_sketch": "CFEngine::sketch_template",
                    "source_scalar": "deploy_path",
                    "source_sketch": "VCS::vcs_mirror",
                    "destination_list": "mylist"
                }
            }
        },
        "log": [],
        "tags": {}
    }
}
```

#### `compose`

The `compose` command defines a composition.  It returns the same data as `compositions`.

```json
{
    dc_api_version: "0.0.1",
    request: {
        compose: {
            mirror_to_template_1: {
                destination_sketch: "CFEngine::sketch_template",
                destination_list: "mylist",
                source_sketch: "VCS::vcs_mirror",
                source_scalar: "deploy_path"
            },
            mirror_to_template_2: {
                destination_sketch: "CFEngine::sketch_template",
                destination_scalar: "myip",
                source_sketch: "VCS::vcs_mirror",
                source_scalar: "deploy_path"
            }
        }
    }
}
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "compositions": {
                "mirror_to_template_2": {
                    "destination_sketch": "CFEngine::sketch_template",
                    "source_scalar": "deploy_path",
                    "source_sketch": "VCS::vcs_mirror",
                    "destination_scalar": "myip"
                },
                "mirror_to_template_1": {
                    "destination_sketch": "CFEngine::sketch_template",
                    "source_scalar": "deploy_path",
                    "source_sketch": "VCS::vcs_mirror",
                    "destination_list": "mylist"
                }
            }
        },
        "log": [],
        "tags": {
            "compose": 1
        }
    }
}
```

#### `decompose`

The `decompose` command undefines a composition by name.  It returns the same data as `compositions`.

```json
{ dc_api_version: "0.0.1", request: {decompose: "mirror_to_template_1" } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "compositions": {
                "destination_sketch": "CFEngine::sketch_template",
                "source_scalar": "deploy_path",
                "source_sketch": "VCS::vcs_mirror",
                "destination_list": "mylist"
            }
        },
        "log": [],
        "tags": {
            "compose": 1
        }
    }
}
```

(Note that Monty Python has beaten us to this joke by decades with "The Decomposing Composers.")

#### `activations`

The `activations` command lists the defined activations.

```json
{ dc_api_version: "0.0.1", request: {activations:true} }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "activations": {
                "VCS::vcs_mirror": [{
                    "params": ["vcs_base", "git_mirror_core"],
                    "environment": "testing",
                    "target": "~/.cfagent/inputs/sketches"
                },
                {
                    "params": ["vcs_base", "svn_mirror_thrift"],
                    "environment": "testing",
                    "target": "~/.cfagent/inputs/sketches"
                }],
                "CFEngine::sketch_template": [{
                    "params": ["incomplete_sketch"],
                    "environment": "testing",
                    "target": "~/.cfagent/inputs/sketches",
                    "compositions": ["mirror_to_template_1", "mirror_to_template_2"]
                }]
            }
        },
        "log": [],
        "tags": {}
    }
}
```

#### `activate`

The `activate` command defines a new activation of a sketch.

An activation is a matching of a sketch bundle with parameters, a run
environment, and optionally compositions.  The sketch name is matched with a
target (so the API knows which installed sketch to inspect), a run environment
name, and a list of parameter names.

```json
{ dc_api_version: "0.0.1", request: {activate: { "VCS::vcs_mirror": { target: "~/.cfagent/inputs/sketches", environment: "testing", params: [ "vcs_base", "git_mirror_core" ] } } } }
```

The sketch bundle will be selected based on which one is satisfied by the given
parameters and compositions.  You can use the `__bundle__` parameter key to
specify the bundle explicitly.

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "activate": {
                "VCS::vcs_mirror": {
                    "params": ["vcs_base", "git_mirror_core"],
                    "environment": "testing",
                    "target": "~/.cfagent/inputs/sketches"
                }
            }
        },
        "log": [],
        "tags": {
            "VCS::vcs_mirror": 1
        }
    }
}
```

You can pass a `identifier` parameter to an `activate` command, which can then
be used to `deactivate` an activation specifically, and which will show up in
the classes and prefixes of that activation.

You can pass a `metadata` parameter to an `activate` command, which will show up
under the `activation` key in the metadata.

You can pass a `target` parameter to an `activate` command with an install location,
which will only activate sketches that exist in that location.

##### option: `compose`

When the `activate` command has a `compose` key with a list of composition
names, those compositions are considered whenever the parameters alone are not
enough to activate the sketch.  Thus compositions and parameters work together,
as late and immediate bindings of the passed data respectively.

#### `deactivate`

The `deactivate` command removes sketch activations.  It can take either the
name of a sketch or `true` to indicate all activations should be removed.

```json
{ dc_api_version: "0.0.1", request: {deactivate: "VCS::vcs_mirror" } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "deactivate": {
                "VCS::vcs_mirror": 1
            }
        },
        "log": [],
        "tags": {
            "deactivate": 1
        }
    }
}
```

```json
{ dc_api_version: "0.0.1", request: {deactivate: true } }
```

(No activations existed at this point, so the return data is empty.)

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {},
        "log": [],
        "tags": {}
    }
}
```

#### `definitions`

The `definitions` command lists the parameter definitions.  This is the DC API's
central library of knowledge.  Every parameter definition is a source of
configuration data (like a CFEngine common bundle, but applied directly to a
sketch bundle).  Parameter definitions have names, which are used when you want
to activate a sketch, and can contain more than one sketch's parameters or only
part of a sketch's parameters.

```json
{ dc_api_version: "0.0.1", request: {definitions:true} }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "definitions": {
                "simple_ssh": {
                    "Security::SSH": {
                        "params": {
                            "X11Forwarding": "yes",
                            "Protocol": "2",
                            "PermitRootLogin": "yes"
                        }
                    }
                },
            }
        },
        "log": [],
        "tags": {}
    }
}
```

#### `define`

The `define` command creates a parameter definition with a name.  The example
here creates some base parameters for the `VCS::vcs_mirror` sketch and then lays
specific configuration to mirror the [https://github.com/cfengine/core.git]
repository's master branch from Git.  In this case, we do it in two steps, but
could have done it in one step.

Note that the reply doesn't tell you more than "I got it, thanks."

You can use the `function` expression in data, as shown below, to make sure that
the DC API will make a function call and not just pass a string.  So, instead of
`getenv("LOGNAME", "128")` you need to use
`{ "function": "getenv", "args": ["LOGNAME", "128"] }` to make sure the function
call is preserved.


```json
{ dc_api_version: "0.0.1", request: {define: { "vcs_base": { "VCS::vcs_mirror": { options: { parent_dir: { owner: { "function": "getenv", "args": ["LOGNAME", "128"] }, group: { "function": "getenv", "args": ["LOGNAME", "128"] }, perms: "755", ensure: true }, nowipe: true, vcs: { runas: { "function": "getenv", "args": ["LOGNAME", "128"] }, umask: "000" } } } } } } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "define": {
                "vcs_base": 1
            }
        },
        "log": [],
        "tags": {
            "vcs_base": 1
        }
    }
}
```

```json
{ dc_api_version: "0.0.1", request: {define: { "git_mirror_core": { "VCS::vcs_mirror": { vcs: "/usr/bin/git", path: "/tmp/q/cfengine-core", branch: "master", origin: "https://github.com/cfengine/core.git" } } } } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "define": {
                "git_mirror_core": 1
            }
        },
        "log": [],
        "tags": {
            "git_mirror_core": 1
        }
    }
}
```

#### `undefine`

The `undefine` command removes a parameter definition by name.  You can pass a
list of string parameter definition names or simply `true` to remove all the
parameter definitions.

```json
{ dc_api_version: "0.0.1", request: {undefine: ["git_mirror_core"] } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "undefine": {
                "git_mirror_core": "1"
            }
        },
        "log": [],
        "tags": {
            "git_mirror_core": 1
        }
    }
}
```

#### `environments`

The `environments` command lists the run environments.

A run environment is a common bundle of general settings.  It affects the
execution of bundles globally, so it's not intended to be specific for each
bundle activation.

The sketch bundle chooses to have a run environment by specifying a parameter
with type `environment`.  Only a run environment can satisfy that API parameter.

Good examples of run environments are *production*, *production_debug*, or
*development_nodebug*.  In a run environment you'd expect to find at least the
`activated`, `verbose`, and `test` variables.  For each of those, the DC API
will also provide a class named `runenv_ENVIRONMENTNAME_ENVIRONMENTVARIABLE`.
Here's an example of a `testing` run environment, as it appears in the generated
runfile:

```
bundle common testing
{
  vars:
      "activated" string => "1";
      "env_vars" slist => { "activated", "test", "verbose" };
      "test" string => "1";
      "verbose" string => "1";
  classes:
      "runenv_testing_activated" expression => "any";
      "runenv_testing_test" expression => "any";
      "runenv_testing_verbose" expression => "any";
}
```

And here is the definition of that run environment:

```json
{ dc_api_version: "0.0.1", request: {environments:true} }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "environments": {
                "testing": {
                    "verbose": "1",
                    "test": "1",
                    "activated": "1"
                }
            }
        },
        "log": [],
        "tags": {}
    }
}
```

The last thing to note is that any run environment variable can have values
other than `true` and `false`.  If they are a string, then that string is a
class expression.  So, for instance, if `activated` is `Monday` then the run
environment will only be activated on Mondays.

If `activated` is a key-value array with the key `include` pointing to an array
of regular expressions, then every element of that array will be AND-ed in a
classmatch.  So, if for the environment _testing_ you specify:

```
activated: { include: [ "x", "y", "regex.*" ] }
```

That will produce, in the runfile,

```
classes:
  "runenv_testing_activated" and => { classmatch("x"), classmatch("y"), classmatch("regex.*") };
```
It's trivial to do an OR with alternation in the regular expression.

#### `define_environment`

The `define_environemnt` command defines a run environment.  The `testing`
example above can be defined like so:

```json
{ dc_api_version: "0.0.1", request: {define_environment: { "testing": { activated: true, test: true, verbose: true } } } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "define_environment": {
                "testing": 1
            }
        },
        "log": [],
        "tags": {
            "testing": 1
        }
    }
}
```

Again, remember that each of those variables can be a string, to be interpreted
as a class expression, and that you can have more than those three variables.

#### `undefine_environment`

The `undefine_environemnt` command removes a run environment.  It takes a list
of environment names.

```json
{ dc_api_version: "0.0.1", request: {undefine_environment: [ "testing" ] } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "undefine_environment": {
                "testing": "1"
            }
        },
        "log": [],
        "tags": {
            "testing": 1
        }
    }
}
```

#### `validations`

The `validations` command lists the data validations.

The data validations are just strings that have a key-value array associated
with them.  Specific keys trigger specific validation behavior in order, as
follows.  Note that the examples below are not necessarily in your API
installation already.

```json
// only the inside of the request is shown for brevity
define_validation: { DIGITS: { valid_regex: "^[0-9]+$" } }
define_validation: { NUMBER: { derived: [ "DIGITS" ] } }
define_validation: { AB: { choice: [ "A", "B" ] } }
define_validation: { 8BIT_NUMBER: { minimum_value: 0, maximum_value: 255 } }
define_validation: { LIST_OF_NUMBERS: { list: [ "NUMBER" ] } }
define_validation: { MOG_SEQUENCE: { sequence: [ "OCTAL", "UID", "GID"	 ] } }
define_validation: { ARRAY_OF_NUMBERS_TO_URLS: { array_k: [ "NUMBER" ], array_v: [ "URL" ] } }
```

* `derived` defines a parent data validation.  So a _NUMBER_ validation requires
  that _DIGITS_ and any other parent data validations be checked first.

* `choice` defines a list of exact string matches.  So _AB_ must be given `A` or
  `B` to pass validation.

* `minimum_value` and then `maximum_value` are numeric checks.  So _8BIT_NUMBER_
  has to be between 0 and 255.  Any invalid numbers, e.g. `hello`, will be
  treated as 0.

* `invalid_regex` and then `valid_regex` are regular expressions written as
  strings.  They follow the Perl regex syntax right now.  So _DIGITS_ can only
  contain the decimal digits 0 through 9 and will reject the empty string `` or
  `hello`.

* `invalid_ipv4` and `valid_ipv4` are TODO.

* `list` ensures that the given data is a list of one of several data types.  So
  in the example, _LIST_OF_NUMBERS_ will check that every element passes the
  _NUMBER_ validation.

* `sequence` is like a record: it ensures that the data is a sequence (list) of
  the given data types.  So for example, _MOG_SEQUENCE_ has to have three
  elements, of which the first one passes _OCTAL_ validation, the second passed
  _UID_ validation, and the third passes _GID_ validation.
  
* `array_k` and `array_v` are almost exactly like `list` but they validate the
  keys and values of a key-value array, respectively, against a list of several
  data types.  So _ARRAY_OF_NUMBERS_TO_URLS_ requires that every key pass the
  _NUMBER_ validation and every value pass the _URL_ validation.

#### `define_validation`

The `define_validation` command defines a data validation.  In the return data
you will find all the currently defined data validations.

```json
{ dc_api_version: "0.0.1", request: {define_validation: { NONEMPTY_STRING: { valid_regex: "." } } } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "validations": {
                "NONEMPTY_STRING": {
                    "valid_regex": "."
                },
            }
        },
        "log": [],
        "tags": {
            "define_validation": 1
        }
    }
}
```


#### `undefine_validation`

The `undefine_validation` command removes a data validation by name.

```json
{ dc_api_version: "0.0.1", request: {undefine_validation: "NONEMPTY_STRING" } }'
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "validations": {
                "valid_regex": "."
            }
        },
        "log": [],
        "tags": {
            "undefine_validation": 1
        }
    }
}
```

#### `validate`

The `validate` command validates data using a named data validation.

```json
{ dc_api_version: "0.0.1", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: { "20": "http://this.that", "30": "not a URL" } } } }
```

It's useful to look at the log output here.  This example failed:

```
DCAPI::log4(Validation.pm:73): Validating ARRAY_OF_NUMBERS_TO_URLS against data '{"30":"not a URL","20":"http://this.that"}'
DCAPI::log4(Validation.pm:282): Validating ARRAY_OF_NUMBERS_TO_URLS: checking 'array_k' is ["NUMBER"]
DCAPI::log4(Validation.pm:73): Validating NUMBER against data '30'
DCAPI::log4(Validation.pm:73): Validating DIGITS against data '30'
DCAPI::log4(Validation.pm:166): Validating DIGITS: checking valid_regex ^[0-9]+$
DCAPI::log4(Validation.pm:85): Validating NUMBER: checking parent data type DIGITS
DCAPI::log4(Validation.pm:73): Validating NUMBER against data '20'
DCAPI::log4(Validation.pm:73): Validating DIGITS against data '20'
DCAPI::log4(Validation.pm:166): Validating DIGITS: checking valid_regex ^[0-9]+$
DCAPI::log4(Validation.pm:85): Validating NUMBER: checking parent data type DIGITS
DCAPI::log4(Validation.pm:282): Validating ARRAY_OF_NUMBERS_TO_URLS: checking 'array_v' is ["URL"]
DCAPI::log4(Validation.pm:73): Validating URL against data 'not a URL'
DCAPI::log4(Validation.pm:166): Validating URL: checking valid_regex ^[A-Za-z]{3,9}://.+
DCAPI::log4(Validation.pm:73): Validating URL against data 'http://this.that'
DCAPI::log4(Validation.pm:166): Validating URL: checking valid_regex ^[A-Za-z]{3,9}://.+
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": false,
        "errors": ["Could not validate any of the allowed array_v types [URL]"],
        "error_tags": {
            "array_v": 1,
            "validation": 1
        },
        "data": {},
        "log": [],
        "tags": {}
    }
}
```

This example succeeded:

```json
{ dc_api_version: "0.0.1", request: {validate: { validation: "ARRAY_OF_NUMBERS_TO_URLS", data: { "20": "http://this.that", "30": "http://this.that2" } } } }
```

```
DCAPI::log4(Validation.pm:73): Validating ARRAY_OF_NUMBERS_TO_URLS against data '{"30":"http://this.that2","20":"http://this.that"}'
DCAPI::log4(Validation.pm:282): Validating ARRAY_OF_NUMBERS_TO_URLS: checking 'array_k' is ["NUMBER"]
DCAPI::log4(Validation.pm:73): Validating NUMBER against data '30'
DCAPI::log4(Validation.pm:73): Validating DIGITS against data '30'
DCAPI::log4(Validation.pm:166): Validating DIGITS: checking valid_regex ^[0-9]+$
DCAPI::log4(Validation.pm:85): Validating NUMBER: checking parent data type DIGITS
DCAPI::log4(Validation.pm:73): Validating NUMBER against data '20'
DCAPI::log4(Validation.pm:73): Validating DIGITS against data '20'
DCAPI::log4(Validation.pm:166): Validating DIGITS: checking valid_regex ^[0-9]+$
DCAPI::log4(Validation.pm:85): Validating NUMBER: checking parent data type DIGITS
DCAPI::log4(Validation.pm:282): Validating ARRAY_OF_NUMBERS_TO_URLS: checking 'array_v' is ["URL"]
DCAPI::log4(Validation.pm:73): Validating URL against data 'http://this.that2'
DCAPI::log4(Validation.pm:166): Validating URL: checking valid_regex ^[A-Za-z]{3,9}://.+
DCAPI::log4(Validation.pm:73): Validating URL against data 'http://this.that'
DCAPI::log4(Validation.pm:166): Validating URL: checking valid_regex ^[A-Za-z]{3,9}://.+
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {},
        "log": [],
        "tags": {}
    }
}
```

#### `regenerate`

The `regenerate` command writes the API runfile (as specified in the API
configuration) from all the known activations, compositions, run environments,
parameter definitions, and data validations.

The command does not allow the user to change the runfile type (standalone or
not) or location, as that is a possible security risk.

#### `regenerate_index`

The `regenerate_index` command takes a directory parameter (string) and writes
the `cfsketches.json` index from all the sketches found in a given directory.
The directory must be local and listed in the API configuration's
`recognized_sources`.  The command returns an error if the index could not be
written or if an error happened while loading any sketch.json files.

```json
{ dc_api_version: "0.0.1", request: {regenerate_index: "~/source/cfengine/design-center/sketches" } }
```

```
DCAPI::log3(DCAPI.pm:1500): Regenerating index: searching for sketches in ~/source/cfengine/design-center/sketches
DCAPI::log3(DCAPI.pm:1523): Regenerating index: on sketch dir applications/memcached
...
DCAPI::log3(DCAPI.pm:1523): Regenerating index: on sketch dir web_servers/apache
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {},
        "log": [],
        "tags": {}
    }
```

#### `test`

The `test` command tests *installed* sketches.  It always returns true if the
test harness ran, even if the individual tests failed.  It's up to you to check
the result of each sketch's test.

Here are examples of two `test` commands.  The first one tests everything
installed (shown when no sketches were installed for brevity; see below for a
full test example).

```json
{ dc_api_version: "0.0.1", request: {test: true } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "coverage": 0,
            "test": {},
            "total": 0
            }
        },
        "log": [],
        "tags": {}
    }
}
```

Under `data` you will find a `coverage` and a `total` key, which respectively
represent the number of covered sketches and the total number of sketches
inspected.  So if you asked to test 10 sketches but only one had any test
scripts, your coverage would be 1/10.

The top-level key under `data.test` is the name of the repository, which is
always a local directory.

The next one takes *terms* and tests all the sketches whose name satisfies the
*terms*.  The return format is the same: for each repository and each sketch
tested, you'll get a key-value array with keys `log` (the text log of the
output); `failed` (with tests that failed); and `total` (with all the tests).

The format inside each test is according to the Perl module `Test::Harness`.
For instance the `good` key will be `1` if all the planned tests succeeded.

The `bench` key will give you some timings, but more precise timings may be
added in the future.  Do not depend on the format of the `bench` value.
    
```json
{ dc_api_version: "0.0.1", request: {test: ["Applications::Memcached"] } }
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "test": {
                "/home/tzz/.cfagent/inputs/sketches": {
                    "Applications::Memcached": {
                        "log": "/home/tzz/.cfagent/inputs/sketches/applications/memcached/test.pl .. \n1..6\n# Running under perl version 5.014002 for linux\n# Current time local: Tue May  7 18:08:08 2013\n# Current time GMT:   Tue May  7 22:08:08 2013\n# Using Test.pm version 1.25_02\nok 1\nok 2\nok 3\nok 4\nok 5\nok 6\nok\n",
                        "failed": {},
                        "total": {
                            "files": 1,
                            "max": 6,
                            "bonus": 0,
                            "skipped": 0,
                            "sub_skipped": 0,
                            "ok": 6,
                            "bad": 0,
                            "good": 1,
                            "tests": 1,
                            "bench": " 1 wallclock secs ( 0.02 usr  0.00 sys +  0.45 cusr  0.01 csys =  0.48 CPU)",
                            "todo": 0
                        }
                    }
                }
            }
        },
        "log": [],
        "tags": {}
    }
}
```

You can skip the actual testing and just get the coverage if you give the `test`
command the `coverage` parameter.  Here's how you can inspect the coverage of
every single installed sketch:

```json
{"dc_api_version":"0.0.1","request":{"coverage":1,"test":["1"]}}
```

```json
{
    "api_ok": {
        "warnings": [],
        "success": true,
        "errors": [],
        "error_tags": {},
        "data": {
            "coverage": 7,
            "test": {
                "/home/tzz/.cfagent/inputs/sketches": {
                    "System::Syslog": 0,
                    "Networking::NTP::Client": 0,
// ...
                    "Packages::installed": 1,
                    "CFEngine::dclib::3.5.0": 1,
                }
            },
            "total": 32
        },
        "log": [],
        "tags": {}
    }
}```

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

If you specify the array `filter_inputs` under `runfile`, any inputs matching
any elements in that array will be omitted from the generated runfile.  That way
you can, for example, exclude the `cfengine_stdlib.cf` that Design Center
provides.

#### `vardata`

The file location where the API will record all data.

#### Full `config.json` example

```json
{
 log: "STDERR",
 log_level: 4,
 repolist: [ "~/.cfagent/inputs/sketches" ],
 recognized_sources: [ "~/source/design-center/sketches" ],
 runfile: { location: "~/.cfagent/inputs/api-runfile.cf", standalone: true, relocate_path: "sketches", filter_inputs: [ "some bad file" ] },
 vardata: "~/.cfagent/vardata.conf",
}
```
