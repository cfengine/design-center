# Writing a Design Center sketch

## Design Center HOWTO series

### Author: Ted Zlatanov <tzz@lifelogs.com>

### Version: 1.0.0

### sketch.json

You need to put this in `sketch.json` and create the corresponding files as
listed in the `manifest`, and the corresponding bundle as listed in the API.

    {
        manifest:
        {
            "main.cf": {desc: "main file" },
            "test.cf": {comment: "Test Policy"},
            "params/example.json": {comment: "Example parameters to report on a few hosts connectivity."}
        },

        metadata:
        {
            name: "Utilities::ping_report",
    	    description: "Report on pingability of hosts",
            version: 1.2,
            license: "MIT",
            tags: ["cfdc"],
            authors: ["Nick Anderson <nick@cmdln.org>", "Ted Zlatanov <tzz@lifelogs.com>" ],
            depends: {"CFEngine::stdlib": {version: 105}, "CFEngine::dclib": {}, cfengine: {version: "3.4.0"}, os: ["linux"] }
        },

        api:
        {
            // the key is the name of the bundle!
            ping:
            [
                { type: "environment", name: "runenv", },
                { type: "metadata", name: "metadata", },
                { type: "list", name: "hosts" },
                { type: "string", name: "count" },
                { type: "return", name: "reached", },
                { type: "return", name: "not_reached", },
            ],
    },
    
        namespace: "cfdc_ping",
        inputs: ["main.cf"]
    }

This definition says: the sketch has 3 files as listed (the minimum recommended
set; `test.cf` in particular is very important to ensure the sketch is testable
without JSON imports or any other wizardry).

The `metadata` keys shown are all obvious and mandatory.  Under `depends` you can
list OS and CFEngine version dependencies.

The `namespace` key, if missing, is assumed to be `null` and thus any `api`
bundles are in the `default` namespace.

The `inputs` key lists all the CFEngine inputs that the sketch requires the user
to include.

Finally, the `api` key is a key-value correspondence of bundle name to a list of
bundle parameters.  In the example above, the `ping` bundle takes 4 parameters
and returns 2 things.

The `metadata` parameter type is special: it's an array populated from
`sketch.json`.  So, for example, the list of tags and authors is available to
the sketch itself.

The `environment` parameter type is also special: it defines a run environment.
The run environment is a set of contexts and configuration data that defines a
global context for bundles.  For example, it can express *development* versus
*production* versus *testing*.

Besides `metadata` and `environment`, you can use these data types:

* `string`: a single string.  Nothing fancy.

* `boolean`: same as a string, but either 1 or not-1.  Use `strcmp("1", $(boolean))` to test.

* `list`: a slist.

* `array`: a string naming an array.  Use `$($(arrayvar)[index])` to dereference it.

You also have the `return` data type, which is just like a string.

### main.cf

The `main.cf` file (although you can name it anything, this is suggested) should
be structured like so:

```
body file control
{
      namespace => "cfdc_ping";
}

bundle agent ping(runenv, metadata, hosts, count)
{
  classes:
      "$(vars)" expression => "default:runenv_$(runenv)_$(vars)";

  vars:
      "vars" slist => { "@(default:$(runenv).env_vars)" };
      "$(vars)" string => "$(default:$(runenv).$(vars))";

      # select between test/non-test runs like this

    !test::
      "exec_prefix" string => "", policy => "free";
    test::
      "exec_prefix" string => "/bin/echo ", policy => "free";

    any::
      # note we're using the paths bundle from cfengine_stdlib.cf
      "pinger" string => "$(exec_prefix)$(default:paths.path[ping])", policy => "free";

  methods:
    verbose::
      "metadata" usebundle => default:report_metadata($(this.bundle), $(metadata)),
      inherit => "true";

  reports:
    verbose::
      "$(this.bundle): imported environment '$(runenv)' var '$(vars)' with value '$($(vars))'";
      "$(this.bundle): imported environment '$(runenv)' class '$(vars)' because 'default:runenv_$(runenv)_$(vars)' was defined"
      ifvarclass => "$(vars)";

    cfengine::
      # these are the return values, to be filled by every bundle as needed
      "$(reached_str)" bundle_return_value_index => "reached";
      "$(not_reached_str)" bundle_return_value_index => "not_reached";
}
```

This example shows you how to use the `metadata` parameter and how to import the
run environment through the `runenv` parameter.

