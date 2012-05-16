# -*- mode: ruby -*-
# vi: set ft=ruby :

# This Vagrantfile bootstraps two 64-bit CentOS 6 guests for hub and agent use
# Put together by Nick Silkey <nick@silkey.org>
#
Vagrant::Config.run do |config|

  # setup the box which will run cfhub
  # simulates a policyserver/fileserver
  config.vm.define :cfhub do |cfhub_config|
    cfhub_config.vm.box = "CentOS-6.2-x86_64-minimal"
    cfhub_config.vm.box_url = "http://dl.dropbox.com/u/5585354/CentOS-6.2-x86_64-minimal.box"
    cfhub_config.vm.network :hostonly, "33.33.33.33"
    # cfhub_config.vm.share_folder "masterfiles","/var/cfengine/masterfiles","./masterfiles/"
    # cfhub_config.vm.provision :shell, :path => "cfengine3.sh"
  end

  # setup the box which will run cfagent
  # simulates a client
  config.vm.define :cfagent do |cfagent_config|
    cfagent_config.vm.box = "CentOS-6.2-x86_64-minimal"
    cfagent_config.vm.box_url = "http://dl.dropbox.com/u/5585354/CentOS-6.2-x86_64-minimal.box"
    cfagent_config.vm.network :hostonly, "33.33.33.44"
    # cfagent_config.vm.share_folder "masterfiles","/var/cfengine/masterfiles","./masterfiles/"
    # cfagent_config.vm.provision :shell, :path => "cfengine3.sh"
  end

end
