# ------------ Get from API methods --------------
require 'rest-client'
require 'json'

def call_api(base_uri, path)
  starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  rest_return = RestClient::Request.execute(method: :get,
                                            url: base_uri + path,
                                            :headers => {:accept => :json},
                                            verify_ssl: false)
  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed = ending - starting
  puts "API call took #{elapsed} seconds" if $debug
  rest_return
end

def get_vsphere_providers(base_uri, path)
  puts "In get_vsphere_providers, path: #{path}" if $debug
  result = JSON.parse(call_api(base_uri, path))
  result['vsphere'].is_a?(Array) ? result['vsphere'] : result['vsphere'].nil? ? [] : [result['vsphere']]
end

# ----

def retrieve(base_uri, path)
  puts "In retrieve, path: #{path}" if $debug
  result = JSON.parse(call_api(base_uri, path))
  result.is_a?(Array) ? result : result.nil? ? [] : [result]
end

# ----

def get_mappings(base_uri, path)
  puts "In get_mappings, path: #{path}" if $debug
  result = JSON.parse(call_api(base_uri, path))
  vms_per_host(hosts_per_cluster(clusters_per_datacenter(datacenters_per_database(result))))
end

# ----

def get_folder_paths(base_uri, path)
  puts "In get_folder_paths, path: #{path}" if $debug
  folders = {}
  api_folders = JSON.parse(call_api(base_uri, path))
  api_folders.each do |folder|
    folders[folder['id']] = find_folder_path(api_folders, folder)
  end
  folders
end

# ----------- End of Get methods --------------