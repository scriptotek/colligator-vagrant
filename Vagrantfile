# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/trusty64"
  config.vm.network "private_network", ip: "172.28.128.9"
  # config.vm.network "forwarded_port", guest: 80, host: 4280, auto_correct: true
  # config.vm.network "forwarded_port", guest: 3306, host: 4206, auto_correct: true

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048

    # Use the NAT hosts DNS resolver as it's faster
    # <http://serverfault.com/a/595010/221948>
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # Use a non-login shell to avoid stdin error messages
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.provision :shell, :path => "provision/provision.sh"


  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "colligator-backend/", "/var/www/backend"
  config.vm.synced_folder "colligator-frontend/", "/var/www/frontend"
  config.vm.synced_folder "provision/", "/provision"
  # config.vm.synced_folder "logs/", "/var/log"

end
