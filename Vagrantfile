Vagrant.configure("2") do |config|
  config.vm.box = "fedora/37-cloud-base"

  config.vm.provider "libvirt" do |v|
    v.memory = "6144"
    v.cpus = 4
  end

  config.vm.provision "shell", privileged: false, reset: true do |s|
    s.path = 'install_dependencies_1.sh'
  end

  config.vm.provision "shell", privileged: false do |s|
    s.path = 'install_dependencies_2.sh'
  end

  config.vm.provision "shell", privileged: false do |s|
    s.path = 'setup_func_kind.sh'
  end
end
