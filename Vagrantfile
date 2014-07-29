VM_MEMORY = ENV.fetch("VM_MEMORY", 6*1024).to_i
VM_CORES = ENV.fetch("VM_CORES", 4).to_i

Vagrant.configure('2') do |config|

  config.vm.hostname = 'bosh'
  config.vm.box = "precise64"
  config.vm.network :private_network, ip: '192.168.30.4'

  config.vm.provider :vmware_fusion do |v, override|
    override.vm.box_url = "http://files.vagrantup.com/precise64_vmware.box"
    v.vmx["numvcpus"] = VM_CORES
    v.vmx["memsize"] = VM_MEMORY
  end

end
