# Data::Triggers::Jenkins version 1.0

License: MIT
Tags: classes, trigger, notification, sketchify_generated, jenkins, persistent, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Trigger behavior from a Jenkins successful build to stage some artifacts
# Purpose

Data::Triggers::Jenkins shows how to handle external notifications from Jenkins.

## Jenkins triggers

You need to install the Jenkins plugin as explained here: 
https://github.com/cfengine/vagrant-cfe/blob/master/README-jenkins.md

The policy logs will be slightly different from what's described there, because
you're using this Design Center sketch.

The configuration is to specify the Jenkins plugin's generated module
(`module_run` set to `/tmp/jenkins-postbuild` if you followed the guide above);
then to specify the module namespace (`module_namespace` is then
`jenkins_postbuild`); and finally the `source_suffix` where artifacts reside
under the Jenkins workspace (e.g. `myartifacts/`) and a `destination`,
e.g. `/var/tmp/deployment`.

Now, whenever Jenkins builds successfully, a special token (class) will be
created for CFEngine's next run.  The next run will see that special token and
trigger the deployment, which can be roughly expressed as 

```
rsync -a $WORKSPACE/$source_suffix $destination
```

There is more to it, and you should look inside `jenkins.cf` if you are curious
about the deployment defaults or want to change them.


## Dependencies
CFEngine::stdlib, Utilities::Staging

## API
### bundle: jenkins
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *metadata* (default: none, description: none)

* parameter _string_ *module_run* (default: none, description: Path to Jenkins signalling module, see README.md)

* parameter _string_ *module_namespace* (default: none, description: Namespace of Jenkins signalling module, see README.md)

* parameter _string_ *source_suffix* (default: none, description: Directory in the Jenkins workspace to deploy, see README.md)

* parameter _string_ *destination* (default: none, description: Destination for build artifacts, see README.md)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

