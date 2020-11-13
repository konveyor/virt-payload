# ------------ Utility methods ---------------
require 'tempfile'
require 'pathname'
require 'rubygems/package'

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

def disks(disks)
  formatted_disks = []
  disks.each do |disk|
    formatted_disks << { "device_type": "disk", "filename": disk["file"] }
  end
  formatted_disks
end

# ----

def shared_disk(disks)
  !disks.select { |disk| disk["shared"] == true }.empty?
end

# ----

def rdm_disk(disks)
  !disks.select { |disk| disk["rdm"] == true }.empty?
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

# ----

def package(payload, tempdir = nil, perm = nil)
  file = Tempfile.create(["mtv_inventory-", ".tar.gz"], tempdir)
  file.binmode

  targz(payload, file)

  file.close

  path = Pathname.new(file.path)
  FileUtils.chmod(perm, [path]) if perm

  path 
end

# ----

def targz(file, io = StringIO.new)
  Zlib::GzipWriter.wrap(io) do |gz|
    Gem::Package::TarWriter.new(gz) do |tar|
      tar.add_file_simple("mtv_inventory.json", 0o0444, file.bytesize) do |tar_file|
        tar_file.write(file)
      end
    end
  end
end

# ----

def stream_back(file)
  stream do |out|
    File.open(file,'rb').each do |line|
      out.write line
      out.flush
    end
  end
end

# ------------ End of utility methods ----------------