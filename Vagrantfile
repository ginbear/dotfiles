# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define :sandbox do |config|
    config.vm.box      = "puppetlabs/centos-7.2-64-puppet"
    config.vm.hostname = "sandbox.local"
    config.vm.synced_folder ".", "/vagrant"
    # config.vm.provision :shell, :path => "bootstrap.sh", privileged: false
  end

end
