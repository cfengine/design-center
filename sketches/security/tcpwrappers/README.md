# Security::tcpwrappers - Manage /etc/hosts.{allow,deny}
## AUTHOR
Nick Anderson <nick@cmdln.org>

## PLATFORM
linux

## DESCRIPTION
Flexibly manage `/etc/hosts.allow` and `/etc/hosts.deny`.
Support for full file content management with empty_first parameter.
Support for managing rule presence or absense with ensure_present and
ensure_absent file editing policies.

## SAMPLE USAGE

    body common control {

        bundlesequence => {"main"};

        inputs => { "../../libraries/copbl/cfengine_stdlib.cf", "main.cf" };
    }

    bundle agent main {
    vars:

      "example_debug"                  string => "true";
      "example_example_filename"          string => "/tmp/example_ensure_absent";
      "example_mgmt_policy"            string => "ensure_present";
      "example_empty_first"            string => "true";
      "example_allow[ssh][daemons]"    slist => { "sshd", "sshd1" };
      "example_allow[ssh][clients]"    slist => { "ALL" };
      "example_deny[default][daemons]" slist => { "ALL" };
      "example_deny[default][clients]" slist => { "ALL" };

    methods:
      "test" usebundle => tcpwrappers("main.example_");
    }
