# -*- mode: ruby -*-
# vi: set ft=ruby :

DOMAIN = "fq.dn"
last_ip_octet = 10

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.hostmanager.enabled = true
  # config.hostmanager.manage_host = true

  #TODO add OS as a parameter to build.sh
  config.vm.box = "CentOS-6.6-minimal"
  config.vm.synced_folder "..", "/cdhbuilder"
  config.ssh.password = "vagrant"

  #config.vm.provider :virtualbox do |vb|
    #vb.gui = true
    #vb.customize ["modifyvm", :id, "--memory", "4096"]
    # or use
    # vb.memory = 4096
  #end

  config.vm.define "master", primary: true do |master|
    master.vm.network :forwarded_port, guest: 7180, host: 7180
    master.vm.network :forwarded_port, guest: 8888, host: 8888
    master.vm.network "private_network", ip: "10.0.10.5"
    master.vm.provision :hostmanager
    master.vm.provision "shell", path: "provision/common.sh"
    master.vm.provision "shell", path: "provision/master.sh"
    master.vm.provider :virtualbox do |v|
      v.name = "master"
      #TODO add memory as a parameter to build.sh
      #TODO add CPUs as a parameter to build.sh
      v.customize ["modifyvm", :id, "--memory", "10240"]
    end 
    master.vm.hostname = "master.#{DOMAIN}"
    master.hostmanager.aliases = "master"
    master.vm.provision :hostmanager
  end

end
