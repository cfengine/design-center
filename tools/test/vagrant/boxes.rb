module Boxes

  BOXEN = %w{
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-5.5-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-5.6-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-5.7-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-5.8-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-5.9-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-6.0-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-6.1-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-6.2-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-6.3-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/centos-6.4-x86_64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/ubuntu-10.04-amd64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/ubuntu-10.10-amd64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/ubuntu-11.04-amd64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/ubuntu-11.10-amd64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/ubuntu-12.04-amd64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/ubuntu-12.10-amd64-201306301713.box
https://s3.amazonaws.com/Vagrant_BaseBoxes/ubuntu-13.04-amd64-201306301713.box
http://files.vagrantup.com/precise32.box
http://files.vagrantup.com/lucid32.box
}

  def Boxes.find(name)
    found = BOXEN.grep(/#{name}/)
    return found.first if found.length == 1
    warn "Box name #{name} has " + (found.empty? ? "no matches" : "more than 1 match: #{found.join(' ')}")
    return
  end

  def Boxes.type(name)
    case name

      when /ubuntu/
      return :ubuntu

      when /centos/
      return :centos
    end
  end

end
