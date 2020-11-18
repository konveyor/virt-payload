# ------------ Get from API methods --------------
require 'rest-client'
require 'json'

def call_api(base_uri, path)
  starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts "RestClient using CA cert: #{K8S_SECRET}/service-ca.crt" if $debug
  rest_return = RestClient::Request.execute(method: :get,
                                            url: base_uri + path,
                                            :headers => {:accept => :json},
                                            ssl_ca_file: "#{K8S_SECRET}/service-ca.crt")
                                            # verify_ssl: false)
  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed = ending - starting
  puts "API call took #{elapsed} seconds" if $debug
  rest_return
end

# ----

def get_namespaces(base_uri, path)
  puts "In get_namespaces, path: #{path}" if $debug
  result = JSON.parse(call_api(base_uri, path))
  result.map { |n| n["name"] }
end

# ----

def get_vsphere_providers(base_uri, namespace, path)
  puts "In get_vsphere_providers, namespace/path: #{namespace}#{path}" if $debug
  result = JSON.parse(call_api(base_uri, "/#{namespace}#{path}"))
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