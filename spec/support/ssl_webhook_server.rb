if __FILE__ == $0

  trap(:INT) do
    @server.shutdown
    exit
  end

  def webrick_opts port, options
    {
      Port: port.nil? ? 0 : port,
      Host: "0.0.0.0",
      AccessLog: [],
      SSLCertificate: OpenSSL::X509::Certificate.new(File.open(options[:sslcert]).read),
      SSLPrivateKey: OpenSSL::PKey::RSA.new(File.open(options[:sslkey]).read),
      SSLEnable: true,
      SSLCertName: [ %w[CN localhost] ]
    }
  end

  app = ->(env) { puts "hello"; [200, {}, ['Hello world' + "\n"]] }

  require 'webrick'
  require 'webrick/ssl'
  require 'webrick/https'
  require 'rack'
  require 'rack/handler/webrick'
  require 'net/http'
  require 'openssl'

  options = {
    ssl: true,
    sslkey: 'spec/fixtures/certificates/key.pem',
    sslcert: 'spec/fixtures/certificates/cert.pem'
  }

  #WEBrick::Utils::getservername

  opts = {
    Port: 4444,
    Host: "localhost",
    AccessLog: [],
    SSLEnable: true,
    SSLCertName: [["CN", "localhost"]]
  }

  opts = webrick_opts(4444, options)

  Rack::Handler::WEBrick.run(app, opts) do |server|
    @server = server
  end
end
