require 'json'
require 'date'

class MtvBaseObject
  def to_json(*options)
    as_json(*options).to_json(*options)
  end
end

class Host < MtvBaseObject
  attr_writer :hostname
  attr_writer :ems_ref
  attr_writer :cpu_cores_per_socket
  attr_writer :cpu_total_cores
  attr_writer :ems_cluster
  
  def as_json(options={})
    {
      hostname:             @hostname,
      ems_ref:              @ems_ref,
      cpu_cores_per_socket: @cpu_cores_per_socket,
      cpu_total_cores:      @cpu_total_cores,
      ems_cluster:          @ems_cluster
    }
  end
end

class EmsCluster < MtvBaseObject
  attr_writer :name
  attr_writer :ems_ref
  attr_writer :v_parent_datacenter
  
  def as_json(options={})
    {
      name:                @name,
      ems_ref:             @ems_ref,
      v_parent_datacenter: @v_parent_datacenter
    }
  end
end

class VmDisk < MtvBaseObject
  attr_writer :filename
  attr_writer :device_type
  
  def initialize
    @device_type = "disk"
  end
  
  def as_json(options={})
    {
      device_type: @device_type,
      filename:    @filename
    }
  end
end

class Vm < MtvBaseObject
  attr_writer   :id
  attr_writer   :name
  attr_writer   :firmware
  attr_writer   :cpu_cores_per_socket
  attr_writer   :cpu_total_cores
  attr_writer   :ballooned_memory
  attr_writer   :cpu_affinity
  attr_writer   :numa_node_affinity
  attr_writer   :has_rdm_disk
  attr_writer   :has_encrypted_disk
  attr_writer   :has_passthrough_device
  attr_writer   :has_opaque_network
  attr_writer   :has_vm_ha_config
  attr_writer   :has_vm_drs_config
  attr_writer   :has_vm_affinity_config
  attr_writer   :memory_hot_add_enabled
  attr_writer   :cpu_hot_add_enabled
  attr_writer   :cpu_hot_remove_enabled
  attr_writer   :used_disk_storage
  attr_writer   :host
  attr_writer   :ram_size_in_bytes
  attr_writer   :retired
  attr_accessor :operating_system
  attr_accessor :hardware
  
  def initialize
    @operating_system       = {}
    @hardware               = {}
    @hardware[:disks]       = []
    @retired                = nil
    @cpu_affinity           = nil
    @numa_node_affinity     = nil
    @has_rdm_disk           = false
    @has_encrypted_disk     = false
    @has_passthrough_device = false
    @has_opaque_network     = false
    @has_vm_ha_config       = false
    @has_vm_drs_config      = false
    @has_vm_affinity_config = false
    @memory_hot_add_enabled = false
    @cpu_hot_add_enabled    = false
    @cpu_hot_remove_enabled = false
  end
   
  def as_json(options={})
    {
      id:                     @id,
      name:                   @name,
      firmware:               @firmware,
      cpu_cores_per_socket:   @cpu_cores_per_socket,
      cpu_total_cores:        @cpu_total_cores,
      ballooned_memory:       @ballooned_memory,
      cpu_affinity:           @cpu_affinity,
      numa_node_affinity:     @numa_node_affinity,
      has_rdm_disk:           @has_rdm_disk,
      has_encrypted_disk:     @has_encrypted_disk,
      has_passthrough_device: @has_passthrough_device,
      has_opaque_network:     @has_opaque_network,
      has_vm_ha_config:       @has_vm_ha_config,
      has_vm_drs_config:      @has_vm_drs_config,
      has_vm_affinity_config: @has_vm_affinity_config,
      memory_hot_add_enabled: @memory_hot_add_enabled,
      cpu_hot_add_enabled:    @cpu_hot_add_enabled,
      cpu_hot_remove_enabled: @cpu_hot_remove_enabled,
      used_disk_storage:      @used_disk_storage,
      host:                   @host,
      ram_size_in_bytes:      @ram_size_in_bytes,
      retired:                @retired,
      operating_system:       @operating_system,
      hardware:               @hardware
    }
  end
end

class Ems < MtvBaseObject
  attr_writer   :name
  attr_writer   :api_version
  attr_writer   :emstype_description
  attr_accessor :hosts
  attr_accessor :ems_clusters
  attr_accessor :vms
  
  def initialize
    @vms          = []
    @hosts        = []
    @ems_clusters = []
  end
  
  def as_json(options={})
    {
      name:                @name,
      api_version:         @api_version,
      emstype_description: @emstype_description,
      vms:                 @vms,
      hosts:               @hosts,
      ems_clusters:        @ems_clusters
    }
  end
end

def mock_disk_1
  disk = VmDisk.new
  disk.filename = "[datastore13] pemcg-test01/pemcg-test01.vmdk"
  disk
end

def mock_disk_2
  disk = VmDisk.new
  disk.filename = "[datastore13] pemcg-test02/pemcg-test02.vmdk"
  disk
end

def mock_disk_shared
  disk = VmDisk.new
  disk.filename = "[datastore13] pemcg-shared/pemcg-shared.vmdk"
  disk
end

def mock_vm_1
  vm                                 = Vm.new
  vm.id                              = 2
  vm.name                            = "pemcg-test01"
  vm.firmware                        = "efi"
  vm.cpu_cores_per_socket            = 1
  vm.cpu_total_cores                 = 1
  vm.ballooned_memory                = 2048
  vm.cpu_affinity                    = "0,2"
  vm.has_rdm_disk                    = true
  vm.has_opaque_network              = true
  vm.has_vm_drs_config               = true
  vm.memory_hot_add_enabled          = true
  vm.cpu_hot_add_enabled             = true
  vm.cpu_hot_remove_enabled          = true
  vm.used_disk_storage               = 135580876
  vm.host                            = {"ems_ref" => "host-29"}
  vm.ram_size_in_bytes               = 2147483648
  vm.operating_system[:product_type] = "Linux"
  vm.operating_system[:product_name] = "Red Hat Enterprise Linux Server release 7.4 (Maipo)"
  vm.hardware[:guest_os_full_name]   = "CentOS 7 (64-bit)"
  vm
end

def mock_vm_2
  vm                                 = Vm.new
  vm.id                              = 3
  vm.name                            = "pemcg-test02"
  vm.firmware                        = "bios"
  vm.cpu_cores_per_socket            = 4
  vm.cpu_total_cores                 = 8
  vm.ballooned_memory                = 0
  vm.has_vm_drs_config               = true
  vm.has_vm_ha_config                = true
  vm.used_disk_storage               = 135580876
  vm.host                            = {"ems_ref" => "host-29"}
  vm.ram_size_in_bytes               = 12147483648
  vm.operating_system[:product_type] = "Linux"
  vm.operating_system[:product_name] = "Red Hat Enterprise Linux Server release 8.2 (Ootpa)"
  vm.hardware[:guest_os_full_name]   = "CentOS 8 (64-bit)"
  vm
end

def mock_ems
  ems                     = Ems.new
  ems.name                = "Test VMware"
  ems.api_version         = "6.5"
  ems.emstype_description = "VMware vCenter"
  ems
end

def mock_host
  host                      = Host.new
  host.hostname             = "esx13.v2v.bos.redhat.com"
  host.ems_ref              = "host-29"
  host.cpu_cores_per_socket = 4
  host.cpu_total_cores      = 8
  host.ems_cluster          = {"ems_ref": "domain-c26"}
  host
end

def mock_ems_cluster
  cluster                     = EmsCluster.new
  cluster.name                = "V2V_Cluster"
  cluster.ems_ref             = "domain-c26"
  cluster.v_parent_datacenter = "V2V-DC"
  cluster
end

#  Assemble some mock data

ems = mock_ems
ems.hosts << mock_host
ems.ems_clusters << mock_ems_cluster
[1,2].each do |n| 
  new_vm = self.send("mock_vm_#{n}")
  new_vm.hardware[:disks] << self.send("mock_disk_#{n}")
  new_vm.hardware[:disks] << mock_disk_shared
  ems.vms << new_vm
end

all_vcenters = []
all_vcenters << ems

payload = {
  "data_collected_on": "#{Time.now.utc}",
  "schema": {
    "name": "Mtv"
  },
  "manifest": {
    "manifest": {
      "version": "1.0.0"
    }
  },
  "ManageIQ::Providers::Vmware::InfraManager": all_vcenters
}

puts payload.to_json