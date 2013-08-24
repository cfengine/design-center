# Cloud::Services::VMWare version 1

License: MIT
Tags: cfdc, cloud, vmware, vcli, enterprise_compatible
Authors: Ted Zlatanov <tzz@lifelogs.com>

## Description
Manage VMWare services through the vSphere Perl SDK and other external tools.

## Dependencies
CFEngine::dclib, CFEngine::dclib::3.5.0, CFEngine::stdlib

## API
### bundle: ensure
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

