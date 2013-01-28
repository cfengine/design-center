# "Hello World" in CFEngine and Puppet

## Design Center HOWTO series

### Author: Ted Zlatanov <tzz@lifelogs.com>

### Version: 3.4.1-0

This is a simple "Hello world" example with CFEngine3 and Puppet.

### CFEngine3 hello, world

For CFEngine3, install the CFEngine packages from
[http://cfengine.com/cfengine-linux-distros] and then save the
following to the file `hello.cf`:

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

And then just run `chmod 600 hello.cf; cf-agent -f ./hello.cf`:

    R: Hello, world

### Puppet hello, world

For Puppet, you have to install the Puppet packages from
[http://info.puppetlabs.com/download-pe.html] and then put the
following in `manifests/site.pp`:

    notify { "Hello world" };

Then, run `puppet apply ./site.pp`:

    notice: Hello world
    notice: /Stage[main]//Notify[Hello world]/message: defined 'message' as 'Hello world'
    notice: Finished catalog run in 0.02 seconds
