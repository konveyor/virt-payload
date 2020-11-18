require 'webrick/ssl'

module Sinatra
  class Application
    def self.run!
      server_options = {
	:Host => bind,
	:Port => port
      }
      if ssl_enabled
	server_options.merge!({
	  :SSLEnable => true,
	  :SSLCertificate => OpenSSL::X509::Certificate.new(File.open(ssl_certificate).read),
	  :SSLPrivateKey => OpenSSL::PKey::RSA.new(File.open(ssl_key).read)
        })
      end

      Rack::Handler::WEBrick.run self, server_options do |server|
	[:INT, :TERM].each { |sig| trap(sig) { server.stop } }
	server.threaded = settings.threaded if server.respond_to? :threaded=
	set :running, true
      end
    end
  end
end
