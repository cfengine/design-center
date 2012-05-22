vagrant-cfengine
================
- These are Vagrantfiles which can be fed to [vagrant](http://vagrantup.com/).
- They aim to boostrap 64-bit el6 CentOS quickly with cfengine 3.3.1 installed on them.[1]
- There is a rudimentary drop to a [vagrant shell provisioner](http://vagrantup.com/docs/provisioners/shell.html).[2]
- Vagrant baseboxes built with vagrant 1.0.3, veewee 0.2.3, vbox 4.1.14.

#### Quickstart
    $ git clone git://github.com/filler/vagrant-cfengine.git
    $ cd vagrant-cfengine
    $ vagrant up

#### Using the shell provisioner, local inputs/bundles
    $ git clone git://github.com/filler/vagrant-cfengine.git && cd vagrant-cfengine
    $ git clone git@github.com:filler/my-awesome-cf3-code.git masterfiles
    $ vi Vagrantfile   # uncomment share + provision
    $ vi cfengine3.sh   # as appropriate for null routes, tree manipulation, classes to invoke
    $ vagrant up

- [1]: This is done in the veewee template postinstall via cfengine-community packages (no EPEL).
- [2]: This hack should be deprecated in-favor a vagrant-proper CFEngine provisioner.  Go forth and fork (or sponsor).
