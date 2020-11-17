# ----------- Class definitions --------------

class MtvBaseObject
  def to_json(*options)
    as_json(*options).to_json(*options)
  end
end

# ----

class Host < MtvBaseObject
  attr_writer :hostname
  attr_writer :ems_ref
  attr_writer :cpu_cores_per_socket
  attr_writer :cpu_total_cores
  attr_writer :ems_cluster
  
  def initialize(host)
    @hostname             = host['name']
    @ems_ref              = host['id']
    @cpu_total_cores      = host['cpuCores'].nil? ? 1 : host['cpuCores']
    @cpu_cores_per_socket = host['cpuCores'] / host['cpuSockets'] rescue 1
  end
  
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

# ----

class EmsCluster < MtvBaseObject
  attr_writer :name
  attr_writer :ems_ref
  attr_writer :v_parent_datacenter
  
  def initialize(cluster)
    @name                = cluster['name']
    @ems_ref             = cluster['id']
  end
  
  def as_json(options={})
    {
      name:                @name,
      ems_ref:             @ems_ref,
      v_parent_datacenter: @v_parent_datacenter
    }
  end
end

# ----

class Vm < MtvBaseObject
  attr_accessor :hardware
  attr_accessor :operating_system
  attr_writer   :ballooned_memory
  attr_writer   :cpu_affinity             # VM has a CPU core affinity configuration rule
  attr_writer   :cpu_cores_per_socket
  attr_writer   :cpu_hot_add_enabled
  attr_writer   :cpu_hot_remove_enabled
  attr_writer   :cpu_total_cores
  attr_writer   :ems_ref
  attr_writer   :firmware
  attr_writer   :folder_path
  attr_writer   :has_cluster_dpm_config   # VM is running on a cluster that is configured with Distributed Power Management
  attr_writer   :has_encrypted_disk       # VM has an encrypted disk
  attr_writer   :has_opaque_network       # VM uses a software-defined network such as NSX-T
  attr_writer   :has_passthrough_device   # VM has a SCSI or other pass-through device mapped from the host
  attr_writer   :has_rdm_disk             # VM has a Raw Device Mapped disk
  attr_writer   :has_shared_disk          # VM has a disk that's marked as shared
  attr_writer   :has_sriov_nic            # VM has a NIC configured for SR-IOV
  attr_writer   :has_usb_controller       # VM has a USB controller
  attr_writer   :has_vm_affinity_config   # VM has a VM affinity/anti-affinity rule defined for it
  attr_writer   :has_vm_drs_config        # VM is running on a cluster that's configured with Distributed Resource Sharing
  attr_writer   :has_vm_ft_config         # VM is configured as one of a fault tolerant pair/unit
  attr_writer   :has_vm_ha_config         # VM is running on a cluster that is configured for VM high availability
  attr_writer   :host
  attr_writer   :id
  attr_writer   :memory_hot_add_enabled
  attr_writer   :name
  attr_writer   :numa_node_affinity       # VM has a NUMA node affinity configuration rule
  attr_writer   :ram_size_in_bytes
  attr_writer   :retired
  attr_writer   :used_disk_storage
  
  def initialize(vm)
    @hardware                         = {}
    @hardware['disks']                = []      # set in create_vm
    @hardware['guest_os_full_name']   = vm['guestName']
    @operating_system                 = {}      # set in create_vm
    @operating_system['product_name'] = vm['guestName']    
    @ballooned_memory                 = vm['balloonedMemory']
    @cpu_affinity                     = to_string(vm['cpuAffinity'])
    @cpu_cores_per_socket             = vm['coresPerSocket']
    @cpu_hot_add_enabled              = vm['cpuHostAddEnabled']
    @cpu_hot_remove_enabled           = vm['cpuHostRemoveEnabled']
    @cpu_total_cores                  = vm['cpuCount']
    @ems_ref                          = vm['id']
    @firmware                         = vm['firmware']
    @folder_path                      = ""      # set in create_vm
    @has_cluster_dpm_config           = false   # set in create_vm from cluster attribute
    @has_encrypted_disk               = false   # hard-code as this for now until we can detect it in vCenter
    @has_opaque_network               = false
    @has_passthrough_device           = vm['passthroughSupported']
    @has_rdm_disk                     = false   # set in create_vm
    @has_shared_disk                  = false   # set in create_vm
    @has_sriov_nic                    = vm['sriovSupported']
    @has_usb_controller               = vm['usbSupported']
    @has_vm_affinity_config           = false   # set in create_vm from cluster attribute
    @has_vm_drs_config                = false   # set in create_vm from cluster attribute
    @has_vm_ft_config                 = vm['faultToleranceEnabled']
    @has_vm_ha_config                 = false   # set in create_vm from cluster attribute
    @host                             = ""      # set in create_vm
    @id                               = vm['uuid']
    @memory_hot_add_enabled           = vm['memoryHotAddEnabled']
    @name                             = vm['name']
    @numa_node_affinity               = to_string(vm['numaNodeAffinity'])
    @ram_size_in_bytes                = vm['memoryMB'] * 1048576
    @retired                          = nil   # hard-code as this for compatibility with Migration Analytics v1
    @used_disk_storage                = vm['storageUsed']
  end
   
  def to_string(list)
    str = ""
    list.each.with_index(1) do |e, i|
      str += e.to_s
      str += ',' unless i == list.length
    end
    str
  end
  
  def as_json(options={})
    {
      id:                     @id,
      name:                   @name,
      ballooned_memory:       @ballooned_memory,
      cpu_affinity:           @cpu_affinity,
      cpu_cores_per_socket:   @cpu_cores_per_socket,
      cpu_hot_add_enabled:    @cpu_hot_add_enabled,
      cpu_hot_remove_enabled: @cpu_hot_remove_enabled,
      cpu_total_cores:        @cpu_total_cores,
      ems_ref:                @ems_ref,
      firmware:               @firmware,
      folder_path:            @folder_path,
      has_cluster_dpm_config: @has_cluster_dpm_config,
      has_encrypted_disk:     @has_encrypted_disk,
      has_opaque_network:     @has_opaque_network,
      has_passthrough_device: @has_passthrough_device,
      has_rdm_disk:           @has_rdm_disk,
      has_shared_disk:        @has_shared_disk,
      has_sriov_nic:          @has_sriov_nic,
      has_usb_controller:     @has_usb_controller,
      has_vm_affinity_config: @has_vm_affinity_config,
      has_vm_drs_config:      @has_vm_drs_config,
      has_vm_ft_config:       @has_vm_ft_config,
      has_vm_ha_config:       @has_vm_ha_config,
      host:                   @host,
      memory_hot_add_enabled: @memory_hot_add_enabled,
      numa_node_affinity:     @numa_node_affinity,
      ram_size_in_bytes:      @ram_size_in_bytes,
      retired:                @retired,
      used_disk_storage:      @used_disk_storage,
      hardware:               @hardware,
      operating_system:       @operating_system
    }
  end
end

# ----

class Ems < MtvBaseObject
  attr_writer   :name
  attr_writer   :api_version
  attr_writer   :emstype_description
  attr_accessor :hosts
  attr_accessor :ems_clusters
  attr_accessor :vms
  
  def initialize(ems)
    @vms                 = []
    @hosts               = []
    @ems_clusters        = []
    @name                = ems['name']
    @emstype_description = ems['product']
    @api_version         = ems['apiVersion']
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

# ----------- End of class definitions --------------