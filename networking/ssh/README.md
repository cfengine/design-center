# Configure sshd

Author: Diego Zamboni <diego.zamboni@cfengine.com>

Configure sshd
1. Set configuration parameters
2. Ensure daemon is running

Sample usage:

    body common control
    {
          inputs => { "cfengine_stdlib.cf", "blueprints/ssh/ssh.cf" };
          bundlesequence =>
          { 
            # Install and configure sshd (NOT YET IMPLEMENTED)
            # sshd_install("g.sshd_config"),
            # Only configure sshd
            sshd_config("g.sshd_config"),
            # Configure ssh (client-side configuration) (not yet implemented)
            ssh_config("g.ssh_config")
          };
    }
    
    bundle common g
    {
      vars:
          # SSHD configuration to set
          "sshd_config[Protocol]"           string => "2";
          "sshd_config[X11Forwarding]"      string => "yes";
          "sshd_config[UseDNS]"		string => "no";
    
          # SSH configuration to set, per host (NOT YET IMPLEMENTED)
          # "ssh_config[host1][ForwardX11]"   string => "yes";
          # "ssh_config[host1][ForwardAgent]" string => "yes";
          # "ssh_config[host2][Port]"         string => "2222";
          # "ssh_config[*][Port]"             string => "2022";
    }

Any parameters in sshd_config are entered into the sshd configuration
file (normally /etc/ssh/sshd_config or /etc/sshd_config, depending
on the operating system). Any parameters in ssh_config are entered into
the ssh configuration file (normally /etc/ssh/ssh_config or /etc/ssh_config).
