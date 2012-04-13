# upgrade_cfengine_3_3_0_rpm - Upgrade to CFEngine  Community 3.3.0 via rpm
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
The 3.3.0-1 rpm release has a few bugs that could leave your agents unable to
execute or update policy. See [bug 1068](https://cfengine.com/bugtracker/view.php?id=1068) 
for details.

This sketch works around those bugs to make sure your agents are upgraded and
can continue to get policy updates. Its kind of sloppy sorry.

## REQUIREMENTS
CFEngine community 3.3.0-1 rpms need to be downloaded from the [engine
room](http://cfengine.com/inside/myspace) (free registration required) 
and placed in the files/packages directory.

## SAMPLE USAGE

    body common control
    {
     bundlesequence => { "main" };

     inputs => { 
                "cfengine_stdlib.cf", 
                "sketches/upgrade_cfengine_3_3_0_rpm/upgrade_cfengine_3_3_0_rpm.cf", 
               };

     version => "Community Promises.cf 1.0.0";
    }

    bundle agent main
    {
     reports:
      cfengine_3::
       "--> CFE is running on $(sys.fqhost)"
          comment => "Display message on screen/email",
           handle => "main_reports_cfe_running";

    methods:
        "any" usebundle => upgrade_cfengine_3_3_0_rpm;
    }

