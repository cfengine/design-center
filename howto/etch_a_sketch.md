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
