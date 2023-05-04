Vagrant.configure("2") do |config|
  config.vm.box = "fedora/37-cloud-base"

  config.vm.provider "libvirt" do |v|
    v.memory = "8096"
    v.cpus = 4
  end

  config.vm.provision "shell" do |s|
    s.path = 'install_dependencies.sh'
  end

  config.vm.provision "shell" do |s|
    s.path = 'setup_func_kind.sh'
  end
end
