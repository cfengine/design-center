# Security::UserRisk::LoggedIn - Report on active login sessions
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Report on users with active login sessions

"Every time someone logs onto a system by hand, they jeopardize everyone's understanding of the system."

## Sample Usage

    bundle agent main {
    vars:
      any::
        "risky_users_sketch[debug]" string => "true";
        "risky_users_conf[report]" string => "true";
        "risky_users_conf[kill]" string => "false";
    
    methods:
      any::
        "Report Logged In Users" usebundle => security_userrisk_loggedin("main.risky_users_");
    
    }

