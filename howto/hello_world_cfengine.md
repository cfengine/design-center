# "Hello World" in CFEngine

## Design Center HOWTO series

### Author: Ted Zlatanov <tzz@lifelogs.com>

### Version: 3.4.1-0

This is a simple "Hello world" style example series with CFEngine3

### Prerequisites for CFEngine

Install the CFEngine packages from [http://cfengine.com/cfengine-linux-distros]
and then save the examples to the file `hello.cf`.

Then just run `chmod 600 hello.cf; cf-agent -f ./hello.cf`.

### CFEngine3 hello, world

    body common control
    {
      bundlesequence => { "run" };
    }

    bundle agent run
    {
      reports:
        cfengine::
          "Hello, world";
    }

Output:

    R: Hello, world

### CFEngine3 create file, and copy file locally

You'll need the `cfengine_stdlib.cf` as well.  It's part of the core distribution.

The following creates `/tmp/authorized_keys` from a string, and copies
`/tmp/sudoers.source` to `/tmp/sudoers`.  In both cases, the target
files are not written unless their contents have changed.  Obviously
in real life you'd target `/root/.ssh/authorized_keys` and
`/etc/sudoers` respectively.

    body common control
    {
      inputs => { "cfengine_stdlib.cf" };
      bundlesequence => { "run" };
    }

    bundle agent run
    {
      vars:
        "root_ssh_key" string => "Allowed SSH keys to root go here";

      files:
        "/tmp/authorized_keys"
        perms => mog("600", "root", "root"),
        create => "true",
        edit_defaults => empty,
        edit_line => append_if_no_lines($(root_ssh_key));

        "/tmp/sudoers"
        perms => mog("440", "root", "root"),
        copy_from => local_digest_cp_nobackup("/tmp/sudoers.source");
    }

    body copy_from local_digest_cp_nobackup(from)
    {
      source      => "$(from)";
      compare     => "digest";
      copy_backup => "false";
    }

Output: none

