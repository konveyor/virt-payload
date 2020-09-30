require 'json'
require 'date'
require 'rest-client'
require 'sinatra'
require "sinatra/namespace"

BASE_URI  = "https://inventory-openshift-migration.apps.cluster-jortel.v2v.bos.redhat.com".freeze
PROVIDERS = "/namespaces/openshift-migration/providers".freeze
VMS       = "/vms?detail=1".freeze
HOSTS     = "/hosts?detail=1".freeze
CLUSTERS  = "/clusters?detail=1".freeze
FOLDERS   = "/folders".freeze
TOPOLOGY  = "/tree/host".freeze

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
    @cpu_cores_per_socket = 6
    @cpu_total_cores      = 12
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
    @name    = cluster['name']
    @ems_ref = cluster['id']
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
  attr_writer   :cpu_affinity
  attr_writer   :cpu_cores_per_socket
  attr_writer   :cpu_hot_add_enabled
  attr_writer   :cpu_hot_remove_enabled
  attr_writer   :cpu_total_cores
  attr_writer   :ems_ref
  attr_writer   :firmware
  attr_writer   :folder_path
  attr_writer   :has_encrypted_disk
  attr_writer   :has_opaque_network
  attr_writer   :has_passthrough_device
  attr_writer   :has_rdm_disk
  attr_writer   :has_usb_controller
  attr_writer   :has_vm_affinity_config
  attr_writer   :has_vm_drs_config
  attr_writer   :has_vm_ha_config
  attr_writer   :host
  attr_writer   :id
  attr_writer   :memory_hot_add_enabled
  attr_writer   :name
  attr_writer   :numa_node_affinity
  attr_writer   :ram_size_in_bytes
  attr_writer   :retired
  attr_writer   :used_disk_storage
  
  def initialize(vm)
    @hardware                        = {}
    @hardware['disks']               = []
    @hardware['guest_os_full_name']  = vm['guestName']
    @operating_system                = {}
    @operating_system['product_name'] = vm['guestName']    
    @ballooned_memory                = vm['balloonedMemory']
    @cpu_affinity                    = vm['cpuAffinity']
    @cpu_cores_per_socket            = 1
    @cpu_hot_add_enabled             = vm['cpuHostAddEnabled']
    @cpu_hot_remove_enabled          = vm['cpuHostRemoveEnabled']
    @cpu_total_cores                 = vm['cpuCount']
    @ems_ref                         = vm['id']
    @firmware                        = vm['firmware']
    @folder_path                     = ""
    @has_encrypted_disk              = false
    @has_opaque_network              = false
    @has_passthrough_device          = false
    @has_rdm_disk                    = false
    @has_usb_controller              = false
    @has_vm_affinity_config          = false
    @has_vm_drs_config               = false
    @has_vm_ha_config                = false
    @host                            = ""
    @id                              = vm['uuid']
    @memory_hot_add_enabled          = vm['memoryHotAddEnabled']
    @name                            = vm['name']
    @numa_node_affinity              = nil
    @ram_size_in_bytes               = vm['memoryMB'] * 1048576
    @retired                         = nil
    @used_disk_storage               = 0
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
      has_encrypted_disk:     @has_encrypted_disk,
      has_opaque_network:     @has_opaque_network,
      has_passthrough_device: @has_passthrough_device,
      has_rdm_disk:           @has_rdm_disk,
      has_usb_controller:     @has_usb_controller,
      has_vm_affinity_config: @has_vm_affinity_config,
      has_vm_drs_config:      @has_vm_drs_config,
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
    @emstype_description = "VMware vCenter"
    @api_version         = "6.5"
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

# ------------ Create object methods ----------------

def create_vm(vm, host_ems_ref)
  folder_path                 = @folder_paths[vm["parent"]["ID"]]
  new_vm                      = Vm.new(vm)
  new_vm.cpu_cores_per_socket = 1
  new_vm.host                 = {"ems_ref" => "#{host_ems_ref}"}
  new_vm.folder_path          = folder_path unless folder_path == "vm"
  
  if /Linux/ =~ new_vm.operating_system['product_name']
    new_vm.operating_system['product_type'] = "Linux"
  elsif /Microsoft Windows Server/ =~ new_vm.operating_system['product_name']
    new_vm.operating_system['product_type'] = "ServerNT"
  else
    new_vm.operating_system['product_type'] = "Unknown"
  end
  
  new_vm.hardware['disks'] = format_disks(vm['disks'])
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

# ------------ Utility methods ---------------

def find_folder_path(api_folders, folder)
  if folder["parent"]["Kind"] == "Folder"
    parent = find_folder_path(api_folders, api_folders.detect {|f| f["id"] == folder["parent"]["ID"]})
    parent == "vm" ? path = folder["name"] : path = "#{parent}/#{folder["name"]}"
  else
    path = folder["name"]
  end
  path
end

# ----

def format_disks(disks)
  formatted_disks = []
  disks.each do |disk|
    formatted_disks << { "device_type": "disk", "filename": disk["file"] }
  end
  formatted_disks
end

# ----

def datacenters_per_database(topology)
  datacenters = []
  if topology["kind"] == ""
    unless topology["children"].nil? || topology["children"].empty?
      topology["children"].each do |child|
        datacenters << child if child["kind"] == "Datacenter"
      end
    end
  end
  datacenters
end

# ----
    
def clusters_per_datacenter(dcs)
  clusters = []
  @cluster_dc_map = {}
  dcs.each do |dc|
    if dc["kind"] == "Datacenter"
      unless dc["children"].nil? || dc["children"].empty?
        dc["children"].each do |child|
          if child["kind"] == "Cluster"
            clusters << child
            @cluster_dc_map[child["object"]["id"]] = dc["object"]["name"]
          end
        end
      end
    end
  end
  clusters
end

# ----
  
def hosts_per_cluster(clusters)
  hosts = []
  @host_cluster_map = {}
  clusters.each do |cluster|
    if cluster["kind"] == "Cluster"
      unless cluster["children"].nil? || cluster["children"].empty?
        cluster["children"].each do |child|
          if child["kind"] == "Host"
            hosts << child
            @host_cluster_map[child["object"]["id"]] = cluster["object"]["id"]
          end            
        end
      end
    end
  end
  hosts
end

# ----

def vms_per_host(hosts)
  vms = []
  @vm_host_map = {}
  hosts.each do |host|
    unless host["kind"] != "Host"
      unless host["children"].nil? || host["children"].empty?
        host["children"].each do |child|
          if child["kind"] == "VM"
            vms << child
            @vm_host_map[child["object"]["id"]] = host["object"]["id"]
          end
        end
      end
    end
  end
end

# ------------ End of utility methods ----------------


# ------------ Get from API methods --------------

def call_api(base_uri, path)
  starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  rest_return = RestClient::Request.execute(method: :get,
                                            url: base_uri + path,
                                            :headers => {:accept => :json},
                                            verify_ssl: false)
  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed = ending - starting
  puts "API call took #{elapsed} seconds"
  rest_return
end

def get_vsphere_providers(base_uri, path)
  result = JSON.parse(call_api(base_uri, path))
  result['vsphere'].is_a?(Array) ? result['vsphere'] : result['vsphere'].nil? ? [] : [result['vsphere']]
end

# ----

def retrieve(base_uri, path)
  result = JSON.parse(call_api(base_uri, path))
  result.is_a?(Array) ? result : result.nil? ? [] : [result]
end

# ----

def get_mappings(base_uri, path)
  result = JSON.parse(call_api(base_uri, path))
  vms_per_host(hosts_per_cluster(clusters_per_datacenter(datacenters_per_database(result))))
end

# ----

def get_folder_paths(base_uri, path)
  folders = {}
  api_folders = JSON.parse(call_api(base_uri, path))
  api_folders.each do |folder|
    folders[folder['id']] = find_folder_path(api_folders, folder)
  end
  folders
end

# ----------- End of Get methods --------------

# ------------- Main ---------------------

def extract
  providers       = get_vsphere_providers(BASE_URI, PROVIDERS)
  all_vcenters    = []
  providers.each do |vcenter|
    ems           = create_ems(vcenter)
    vc_link       = vcenter['selfLink']
    @folder_paths = get_folder_paths(BASE_URI, vc_link + FOLDERS)

    get_mappings(BASE_URI, vc_link + TOPOLOGY)

    retrieve(BASE_URI, vc_link + CLUSTERS).each do |cluster|
      ems.ems_clusters << create_cluster(cluster, @cluster_dc_map[cluster['id']])
    end
    
    retrieve(BASE_URI, vc_link + HOSTS).each do |host|
      ems.hosts << create_host(host, @host_cluster_map[host['id']])
    end
  
    retrieve(BASE_URI, vc_link + VMS).each do |vm|
      ems.vms << create_vm(vm, @vm_host_map[vm['id']])
    end

    all_vcenters << ems
  end
  
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
  payload.to_json
end

# ----

namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

  get '/extract' do
    extract
  end
end