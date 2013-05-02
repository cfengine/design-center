About this document
===================

This document provides a step-by-step guide to setup a design center enabled
policyhub on a Debian Squeeze.

Setup the policyhub
===================

* Add this line to your sources.list:

> deb http://cfengine.com/pub/apt squeeze main

* Install cfengine-community:

```sh
wget http://cfengine.com/pub/gpg.key -O- -q | sudo apt-key add -
apt-get update
apt-get install cfengine-community
```

* Bootstrap machine to self and start it up:

```sh
/var/cfengine/bin/cf-agent --bootstrap --policyserver 192.168.122.28
/var/cfengine/bin/cf-agent -IKf update.cf
/var/cfengine/bin/cf-agent -IK
```

Setup Desgin Center
===================

* Install *minimum* pre-reqs:

```sh
apt-get install git libjson-perl libfile-slurp-perl curl make
```

* Clone design center:

```sh
git clone git://github.com/cfengine/design-center.git
```

* Patch the default masterfiles to work with design-center sketches:

```sh
cd /var/cfengine/masterfiles
patch -p1 < /root/design-center/examples/cfengine-community-3.4.2-masterfiles-dc.patch
```

* Setup DC API:

```sh
cd /root/design-center
export DC_API_CMD="/root/design-center/tools/cf-sketch/cf-dc-api.pl /root/design-center/config.json"
echo '
{
 log: "STDERR",
 log_level: 4,
 repolist: [ "/var/cfengine/masterfiles/sketches" ],
 recognized_sources: [ "/root/design-center/sketches" ],
 runfile: {
   location: "/var/cfengine/masterfiles/cf-sketch-runfile.cf",
   standalone: false,
   relocate_path: "sketches"
 },
 vardata: "/root/dc-vardata.conf",
}' > ./config.json
```

* Test the API:

```sh
echo '{ dc_api_version: "0.0.1", request: { } }' | ${DC_API_CMD}
```

Should return:

```json
{"api_ok":{"success":true,"warnings":[],"errors":[],"error_tags":{},"log":["Nothing to do, but we're OK, thanks for asking."],"data":{},"tags":{}}}
```

Activating some sketches
========================

* create a production run environment

```sh
echo '
{
        dc_api_version: "0.0.1",
        request: {
                define_environment: {
                        "production": {
                                activated: true,
                                test: false,
                                verbose: false
                        }
                }
        }
}
' | ${DC_API_CMD}
```

Should return:

```json
{"api_ok":{"success":true,"warnings":[],"errors":[],"error_tags":{},"log":[],"data":{"define_environment":{"production":1}},"tags":{"production":1}}}
```

Install and activate Utilities::abortclasses
--------------------------------------------

* Install Sketch:

```sh
echo '
{
        dc_api_version: "0.0.1",
        request: {
                install: [
                        {
                                sketch: "Utilities::abortclasses",
                                force: true,
                                target: "/var/cfengine/masterfiles/sketches",
                                source: "/root/design-center/sketches"
                        }
                ]
        }
}
' | ${DC_API_CMD}
```

Should return:

```json
{"api_ok":{"success":true,"warnings":[],"errors":[],"error_tags":{},"log":[],"data":{"install":{"/var/cfengine/masterfiles/sketches":{"Utilities::abortclasses":1},"Utilities::abortclasses":{"changelog":"/var/cfengine/masterfiles/sketches/utilities/abortclasses/changelog","README.md":"/var/cfengine/masterfiles/sketches/utilities/abortclasses/README.md","test.cf":"/var/cfengine/masterfiles/sketches/utilities/abortclasses/test.cf","params/example.json":"/var/cfengine/masterfiles/sketches/utilities/abortclasses/params/example.json","main.cf":"/var/cfengine/masterfiles/sketches/utilities/abortclasses/main.cf"}},"inventory_save":1},"tags":{"installation":6,"Utilities::abortclasses":1}}}
```

* Define params:

```sh
echo '
{
        dc_api_version: "0.0.1",
        request: {
                define: {
                        "abortclasses_params": {
				"Utilities::abortclasses": {
					trigger_file: "/COWBOY",
					trigger_context: "any",
					abortclass: "cowboy",
					alert_only: false,
					timeout: {
						enabled: 0,
						action: "abortclasses_pester_lester",
						years: 0,
						months: 0,
						days: 1,
						hours: 0,
						minutes: 0,
						seconds: 0
					}
				}
			}
                }
        }
}
' | ${DC_API_CMD}
```

Should return:

```json
{"api_ok":{"success":true,"warnings":[],"errors":[],"error_tags":{},"log":[],"data":{"define":{"abortclasses_global":1}},"tags":{"abortclasses_global":1}}}
```

* Activate sketch:

```sh
echo '
{
        dc_api_version: "0.0.1",
        request: {
                activate: {
                        "Utilities::abortclasses": {
                                environment: "production",
                                params: [ "abortclasses_params" ]
                        }
                }
        }
}
' | ${DC_API_CMD}
```

Should return:

```json
{"api_ok":{"success":true,"warnings":[],"errors":[],"data":{"activate":{"Utilities::abortclasses":{"environment":"production","params":["abortclasses_params"]}}},"tags":{"Utilities::abortclasses":1},"error_tags":{},"log":[]}}
```

* Regenerate (Install the policy hooks):

```sh
echo '
{
	dc_api_version: "0.0.1",
	request: {
		regenerate: { }
	}
}
' | ${DC_API_CMD}
```

Should return:

```json
{"api_ok":{"success":true,"warnings":[],"errors":[],"data":{},"tags":{},"error_tags":{},"log":[]}}
```

* Run the policy and see the sketch activated:

```sh
cf-agent -IKf update.cf && cf-agent -IKDverbose
```

Should look like:
```
<SNIP>
R: abortclasses_filebased:      timeout[days]: 1
R: abortclasses_filebased:      timeout[hours]: 0
R: abortclasses_filebased:      timeout[minutes]: 0
R: abortclasses_filebased:      timeout[seconds]: 0
R: abortclasses: trigger_context: any not currently defined, will not actually abort
 !! Method invoked repairs
R: --> I'm a policy hub.
 !! Method invoked repairs
```

* Add the following line to /var/cfengine/masterfiles/control/cf_agent.cf, in body agent control, to enable the abort class for cf-agent (making this sketch effective):

> abortclasses => { "cowboy", };

* Test it:

```sh
cf-agent -IKf update.cf && cf-agent -IK
touch /COWBOY
cf-agent -IKf update.cf && cf-agent -IK
rm /COWBOY
```

Should return:

```
R: abortclasses_alert: Warning: system is under manual control!!!
```

Install and activate Utilities::tidy_dir to clean /var/cfengine/outputs
-----------------------------------------------------------------------

* Install Sketch:

```sh
echo '
{
        dc_api_version: "0.0.1",
        request: {
                install: [
                        {
                                sketch: "Utilities::tidy_dir",
                                force: true,
                                target: "/var/cfengine/masterfiles/sketches",
                                source: "/root/design-center/sketches"
                        }
                ]
        }
}
' | ${DC_API_CMD}
```

* Define params:

```sh
echo '
{
        dc_api_version: "0.0.1",
        request: {
                define: {
                        "tidy_dir_var_cfengine_outputs": {
				"Utilities::tidy_dir": {
					dir: "/var/cfengine/outputs",
					days_old: "3",
					recurse: true
				}
			}
                }
        }
}
' | ${DC_API_CMD}
```

* Activate sketch:

```sh
echo '
{
        dc_api_version: "0.0.1",
        request: {
                activate: {
                        "Utilities::tidy_dir": {
                                environment: "production",
                                params: [ "tidy_dir_var_cfengine_outputs" ]
                        }
                }
        }
}
' | ${DC_API_CMD}
```

* Regenerate (Install the policy hooks):

```sh
echo '
{
	dc_api_version: "0.0.1",
	request: {
		regenerate: { }
	}
}
' | ${DC_API_CMD}
```

* Run the policy and see the sketch activated:

```sh
cf-agent -IKf update.cf && cf-agent -IKDverbose
```

Should contain something like:
```
<SNIP>
R: entry: got dir=/var/cfengine/outputs
R: entry: got days_old=3
R: entry: got recurse=1
<SNIP>
```
