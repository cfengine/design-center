# "Hello World" in CFEngine and Puppet

## Design Center HOWTO series

### Author: Ted Zlatanov <tzz@lifelogs.com>

### Version: 3.4.1-0

This is a simple "Hello world" style example series  with CFEngine3 and Puppet.

### Prerequisites for CFEngine and Puppet.

For CFEngine3, install the CFEngine packages from
[http://cfengine.com/cfengine-linux-distros] and then save the
examples to the file `hello.cf`.

Then just run `chmod 600 hello.cf; cf-agent -f ./hello.cf`.

For Puppet, you have to install the Puppet packages from
[http://info.puppetlabs.com/download-pe.html] and then put the
examples in `site.pp`.

Then run `puppet apply ./site.pp`.

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

### Puppet hello, world

    notify { "Hello world" };

Output:

    notice: Hello world
    notice: /Stage[main]//Notify[Hello world]/message: defined 'message' as 'Hello world'
    notice: Finished catalog run in 0.02 seconds

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

### Puppet create file, and copy file locally

The following creates `/tmp/authorized_keys` from a string, and copies
`/tmp/sudoers.source` to `/tmp/sudoers`.  In both cases, the target
files are not written unless their contents have changed.  Obviously
in real life you'd target `/root/.ssh/authorized_keys` and
`/etc/sudoers` respectively.

    file {
      '/tmp/sudoers':
      backup => false,
      checksum => md5,
      owner => 'root',
      group => 'root',
      mode => 0440,
      source => '/tmp/sudoers.source';
    }

    file {
      '/tmp/authorized_keys':
      ensure => present,
      owner => 'root',
      group => 'root',
      mode => 0600,
      content => "Allowed SSH keys to root go here";
    }

Output:

    notice: /Stage[main]//Notify[Hello world]/message: defined 'message' as 'Hello world'
    notice: /Stage[main]//File[/tmp/sudoers]/ensure: defined content as '{md5}b87280cc34b8a968d9cf235fe16adefa'
    notice: Finished catalog run in 0.02 seconds
