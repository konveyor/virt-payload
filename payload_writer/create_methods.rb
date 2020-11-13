# ------------ Create object methods ----------------

def create_vm(vm, id, host_ems_ref, clusters)
  folder_path                 = @folder_paths[vm["parent"]["ID"]]
  cluster                     = clusters[@host_cluster_map[host_ems_ref]]
  new_vm                      = Vm.new(vm)
  new_vm.id                   = id
  new_vm.host                 = {"ems_ref" => "#{host_ems_ref}"}
  new_vm.folder_path          = folder_path unless folder_path == "vm"
  
  if /Linux|CentOS|Ubuntu|Debian|SUSE|Asianux|Fedora|Photon/ =~ new_vm.operating_system['product_name']
    new_vm.operating_system['product_type'] = "Linux"
  elsif /Microsoft Windows Server/ =~ new_vm.operating_system['product_name']
    new_vm.operating_system['product_type'] = "ServerNT"
  else
    new_vm.operating_system['product_type'] = "Unknown"
  end
  
  # Propagate cluster-related attributes as VM boolean flags
  
  new_vm.has_vm_drs_config = cluster['drsEnabled']
  new_vm.has_vm_ha_config  = cluster['dasEnabled']
  #new_vm.has_cluster_dpm_config  = cluster['']
  #new_vm.has_vm_affinity_config  = cluster['']
  
  new_vm.hardware['disks'] = disks(vm['disks'])
  new_vm.has_shared_disk   = shared_disk(vm['disks'])
  new_vm.has_rdm_disk      = rdm_disk(vm['disks'])
  new_vm
end

# ----

def create_host(host, cluster_ems_ref)
  new_host                      = Host.new(host)
  new_host.ems_cluster          = {"ems_ref": "#{cluster_ems_ref}"}
  new_host  
end

# ----

def create_cluster(cluster, dc_name)
  new_cluster                     = EmsCluster.new(cluster)
  new_cluster.v_parent_datacenter = dc_name
  new_cluster
end

# ----

def create_ems(ems)
  Ems.new(ems)
end

# ------------ End of create object methods ----------------