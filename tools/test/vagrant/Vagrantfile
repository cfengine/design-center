# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'optparse'
require 'pp'
require 'ipaddr'

require './boxes'
require './actions'

ours = []

while ARGV.include? '--'
  ours << ARGV.pop
end

ours -= ['--']
ours.reverse!

puts "Command-line options are " + ours.to_s

options= {
  :installer => :core,
  :install_version => nil,
  :setup => [],
  :dctest => [],
  :box => 'ubuntu-13.04',
  :count => 1,
  :ip => "10.1.1.12",
  :bootstrap_ip => nil,
  :dcurl => 'https://github.com/cfengine/design-center.git',
  :dcbranch => 'master',
  :vmname => 'cftester',
  :vmsize => "1024",
  :baseport => "8080",
}

OptionParser.new do |op|
  op.banner = <<EOHIPPUS
Syntax: vagrant [vagrant options] -- OPTIONS

Note that options can be abbreviated.

Example: install on Ubuntu 13.04 from a CFEngine Core master checkout and bootstrap against A.B.C.D
  vagrant up -- --bootstrap_ip A.B.C.D bootstrap

Example: install on Ubuntu 13.04 from the CFEngine APT repo and install Design Center in /var/tmp/dc
  vagrant up -- -ipackages dc
EOHIPPUS

  op.on("--dcurl=[URL]",
        "Design Center URL to check out with Git") do |v|
    options[:dcurl] = v
  end

  op.on("--vmname=[VMNAME]",
        "VM Base name") do |v|
    options[:vmname] = v
  end

  op.on("--vmsize=[VMSIZE]",
        "VM memory size") do |v|
    options[:vmsize] = v
  end

  op.on("--baseport=[BASEPORT]",
        "Base forwarding port") do |v|
    options[:baseport] = v
  end

  op.on("--dcbranch=[BRANCH]",
        "Design Center branch to check out with Git") do |v|
    options[:dcbranch] = v
  end

  op.on("-i[INSTALLER]", "--installer=[INSTALLER]",
        [:none, :core, :packages],
        "Installation method for CFEngine (none, core, packages)") do |v|
    options[:installer] = v
  end

  op.on("--install_version=[VERSION]",
        "Installation version for CFEngine, where applicable") do |v|
    options[:install_version] = v
  end

  op.on("--setup bootstrap,dc",
        Array,
        "Setup steps: (bootstrap, dc, etc.).  Only bootstrap and dc have special treatment.") do |v|
    options[:setup] = v
  end

  op.on("--dctest x,y,z",
        Array,
        "Test sketches: (Sketch1, Sketch2, etc.)") do |v|
    options[:dctest] = v
  end

  op.on("-b[BOX]", "--box=[BOX]",
        "Box to use (precise32, lucid32, ubuntu-VERSION, etc.)") do |v|
    options[:box] = v
  end

  op.on("-I[IP]", "--ip=[IP]",
        "Starting IP to assign to the hosts") do |v|
    ip = IPAddr.new(v)
    abort unless ip
    options[:ip] = v
  end

  op.on("-b[IP]", "--bootstrap=[IP]",
        "Bootstrap IP.  Skipped by default.  With count > 1, if not specified, uses the first element of the --ip range") do |v|
    options[:bootstrap_ip] = v
  end

  op.on("-c[COUNT]", "--count=[COUNT]",
        "Count of boxes to bring up") do |v|
    options[:count] = v.to_i
    if options[:count] > 254
      abort "We can't handle count over 254, sorry"
    end
  end

end.parse!(ours)

# any leftover things are setup steps
options[:setup] += ours

puts "Parsed options from the command line + defaults:"
pp options

unless options[:bootstrap_ip]
  options[:bootstrap_ip] = options[:ip]
end

box = Boxes.find(options[:box])

unless box
  abort "Sorry, the box spec #{options[:box]} did not match a single box we can use.  Bye."
end

puts "Found and using box [#{box}]"

box_type = Boxes.type(box)

unless box_type
  abort "Sorry, the box #{options[:box]} did not have a valid type.  Bye."
end

puts "Found and using box type [#{box_type}]"

puts "Requested instance count [#{options[:count]}]"
puts "Requested instance IP or IP prefix [#{options[:ip]}]"
puts "Requested bootstrap IP [#{options[:bootstrap_ip]}]"

actions = Actions.assemble(Boxes.type(box), options[:installer], options[:install_version], options[:setup], options[:dctest])

printable_version = options[:install_version] || 'latest'

unless actions
  abort "Sorry, the box #{options[:box]} with type #{box_type} and setup steps #{options[:installer]} (version #{printable_version}), #{options[:setup].join(' ')}, #{options[:dctest].join(' ')} did not give us valid steps to follow.  Bye."
end

puts "From setup steps #{options[:installer]} (version #{printable_version}), setup #{options[:setup].join(' ')}, dctest #{options[:dctest].join(' ')}, steps to follow: " + actions.to_s

puts "CFEngine test environment ready!"
puts "Engaging donkey's attention..."

Vagrant.configure("2") do |config|

  config.vm.box = File.basename(box)
  config.vm.box_url = box

  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", 1024]
  end

  #### Define VMs ####

  options[:count].times do |i|
    iprint = i.to_s.rjust(3, '0')
    config.vm.define "#{options[:vmname]}#{iprint}" do |vm_config|

      # Host config
      vm_config.vm.hostname = "#{options[:vmname]}#{iprint}"
      ip = options[:ip]
      # shaddap, it works
      i.times { |c| ip = ip.succ() }

      vm_config.vm.network :private_network, ip: ip

      vm_config.vm.network :forwarded_port, guest: 80, host: options[:baseport].to_i+i

      options[:i] = i
      actions.each do |a|
        args = Actions.process_args(a[:args], options)
        vm_config.vm.provision :shell, :path => "resources/shell_provisioners/#{a[:path]}", :args => args
      end

    end
  end
end

