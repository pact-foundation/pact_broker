if __FILE__ == $0

  SSL_KEY = 'spec/fixtures/certificates/key.pem'
  SSL_CERT = 'spec/fixtures/certificates/cert.pem'

  trap(:INT) do
    @server.shutdown
    exit
  end

  def webrick_opts port
    certificate = OpenSSL::X509::Certificate.new(File.read(SSL_CERT))
    cert_name = certificate.subject.to_a.collect{|a| a[0..1] }
    logger_stream = ENV['DEBUG'] ? $stderr : StringIO.new
    {
      Port: port,
      Host: "0.0.0.0",
      AccessLog: [],
      Logger: WEBrick::Log.new(logger_stream,WEBrick::Log::INFO),
      SSLCertificate: certificate,
      SSLPrivateKey: OpenSSL::PKey::RSA.new(File.read(SSL_KEY)),
      SSLEnable: true,
      SSLCertName: cert_name
    }
  end

  app = ->(_env) { puts "hello"; [200, {}, ['Hello world' + "\n"]] }

  require 'webrick'
  require 'webrick/https'
  require 'rack'
  require 'rack/handler/webrick'

  opts = webrick_opts(4444)

  Rack::Handler::WEBrick.run(app, opts) do |server|
    @server = server
  end
end
