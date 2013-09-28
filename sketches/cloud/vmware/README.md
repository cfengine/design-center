# Cloud::Services::VMWare version 1

License: MIT
Tags: cfdc, cloud, vmware, vcli, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage VMWare services through the vSphere Perl SDK and other external tools.
This sketch will start or stop VMWare VMs.

You have to provide it the names of the start, stop, and count
scripts.  Also you provide a class name for the new machines and a
target count.

The start script will get called with the parameters `PRIOR_COUNT`,
`COUNT`, `CLASS`, `HUB`, and `INSTALL_CFENGINE` (0 or 1).

The stop script takes `PRIOR_COUNT`, `COUNT`, and `CLASS`.

The count script takes just the `CLASS` parameter.

So let's say you activate this sketch with class `cfworker`, target
count 5, and hub 10.2.3.10.

The count script will be called with `cfworker`.  Let's say it returns
0, since no machines were running.  It will keep getting called
whenever the policy is run.

The start script will be called with `0 5 cfworker 10.2.3.10 1`.

If we somehow end up with 10 VMs by accident, the stop script will be
called with `10 5 cfworker`.


## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## API
### bundle: ensure (description: Ensure a specific number of VMs are running, starting or stopping them as needed through custom scripts.)
* parameter _environment_ *runenv* (default: none, description: none)

* parameter _metadata_ *mymetadata* (default: none, description: none)

* parameter _string_ *count* (default: none, description: Number of VMs you want to ensure are running.)

* parameter _string_ *class* (default: none, description: Logical class to assign to the created virtual machines)

* parameter _boolean_ *install_cfengine* (default: none, description: Whether CFEngine should be installed on the new VMs)

* parameter _string_ *hub* (default: none, description: Hub from which the instances should bootstrap)

* parameter _string_ *start_command* (default: none, description: Command to start some VMs.  Parameters: COUNT CLASS HUB INSTALL_CFENGINE)

* parameter _string_ *stop_command* (default: none, description: Command to stop some VMs.  Parameters: COUNT CLASS)

* parameter _string_ *count_command* (default: none, description: Command to count VMs.  Parameters: CLASS)

* parameter _array_ *options* (default: `{}`, description: Options)

* returns _return_ *instance_count* (default: none, description: none)


## SAMPLE USAGE
See `test.cf` or the example parameters provided

