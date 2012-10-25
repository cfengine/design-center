This is a vagrant interface to test Design Center.  Here's how you can use it:

Print all the options:

     vagrant up cftester -- --help

Test Design Center sketches ssh and limits against a Community core checkout, using tzz's DC fork:

     vagrant up cftester -- -icore --dcurl=https://github.com/tzz/design-center.git ssh limits

Check out the VM after the tests have been run (note you have sudo):

    vagrant ssh cftester

Destroy the VM:

    vagrant destroy -f cftester

The currently supported test targets include:

cloud_services, db_install, ssh, aptrepo, yumclient, yumrepo, cpanm,
limits, tcpwrappers, config_resolver, cron, etc_hosts, set_hostname,
sysctl, tzconfig, abortclasses, nagios_plugin_agent, ping_report,
ipverify, vcs_mirror, wordpress
