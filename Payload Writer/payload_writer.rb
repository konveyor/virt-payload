require 'json'
require 'date'
require 'rest-client'
require 'sinatra'
require "sinatra/namespace"

base_uri      = "https://inventory-openshift-migration.apps.cluster-jortel.v2v.bos.redhat.com".freeze
vms_path      = "/namespaces/openshift-migration/providers/vsphere/test/vms?detail=1".freeze
ems_path      = "/namespaces/openshift-migration/providers/vsphere/test/vms/vm-2696".freeze
folders_path  = "/namespaces/openshift-migration/providers/vsphere/test/folders".freeze
topology_path = "/namespaces/openshift-migration/providers/vsphere/test/tree/host".freeze
folders = {}

# ----------- Class definitions --------------

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

def format_disks(disks)
  formatted_disks = []
  disks.each do |disk|
    formatted_disks << { "device_type": "disk", "filename": disk["file"] }
  end
  formatted_disks
end

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
    
def clusters_per_datacenter(topology)
  clusters = []
  topology.each do |obj|
    if obj["kind"] == "Datacenter"
      unless obj["children"].nil? || obj["children"].empty?
        obj["children"].each do |child|
          clusters << child if child["kind"] == "Cluster"
        end
      end
    end
  end
  clusters
end
  
def hosts_per_cluster(topology)
  hosts = []
  topology.each do |obj|
    if obj["kind"] == "Cluster"
      unless obj["children"].nil? || obj["children"].empty?
        obj["children"].each do |child|
          hosts << child if child["kind"] == "Host"
        end
      end
    end
  end
  hosts
end

def vms_per_host(hosts)
  vm_host_map = {}
  hosts.each do |host|
    unless host["kind"] != "Host"
      unless host["children"].nil? || host["children"].empty?
        host["children"].each do |child|
          vm_host_map[child["object"]["id"]] = host["object"]["id"] if child["kind"] == "VM"
        end
      end
    end
  end
  vm_host_map  
end

# ------------ End of utility methods ----------------


# ------------ Get from API methods --------------

def get_vms(base_uri, path)
  rest_return = RestClient::Request.execute(method: :get,
                                            url: base_uri + path,
                                            :headers => {:accept => :json},
                                            verify_ssl: false)
  result = JSON.parse(rest_return)
  result = result.is_a?(Array) ? result : result.nil? ? [] : [result]
end

def get_vm_host_map(base_uri, path)
  
  rest_return = RestClient::Request.execute(method: :get,
                                            url: base_uri + path,
                                            :headers => {:accept => :json},
                                            verify_ssl: false)
  result = JSON.parse(rest_return)
  hosts = hosts_per_cluster(clusters_per_datacenter(datacenters_per_database(result)))
  vms_per_host(hosts)
end

def get_ems(base_uri, path)
  puts "in get_ems"
end

def get_folder_paths(base_uri, path)
  folders = {}
  rest_return = RestClient::Request.execute(method: :get,
                                            url: base_uri + path,
                                            :headers => {:accept => :json},
                                            verify_ssl: false)
  api_folders = JSON.parse(rest_return)
  api_folders.each do |folder|
    folders[folder['id']] = find_folder_path(api_folders, folder)
  end
  folders
end

# ----------- End of Get methods --------------


# ------------ Mock methods -------------------

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

# ------------ End of Mock methods -------------------


# ------------- Main ---------------------

def extract
  @folder_paths = get_folder_paths(base_uri, folders_path)
  
  ems = mock_ems
  vm_host_map = get_vm_host_map(base_uri, topology_path)
  ems.hosts << mock_host
  ems.ems_clusters << mock_ems_cluster
  
  get_vms(base_uri, vms_path).each do |vm|
    ems.vms << create_vm(vm, vm_host_map[vm['id']])
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
end


namespace '/api/v1 ' do

  before do
    content_type 'application/json'
  end

  get '/extract' do
    extract
  end
end