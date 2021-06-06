if __FILE__ == $0
  require "pact_broker"

  DATABASE_CREDENTIALS = {adapter: "sqlite", database: "pact_broker_ssl_database.sqlite3", :encoding => "utf8"}

  app = PactBroker::App.new do | config |
    config.logger = ::Logger.new($stdout)
    config.logger.level = ::Logger::DEBUG
    config.database_connection = Sequel.connect(DATABASE_CREDENTIALS)
  end

  SSL_KEY = "spec/fixtures/certificates/key.pem"
  SSL_CERT = "spec/fixtures/certificates/cert.pem"

  trap(:INT) do
    @server.shutdown
    exit
  end

  def webrick_opts port
    certificate = OpenSSL::X509::Certificate.new(File.read(SSL_CERT))
    cert_name = certificate.subject.to_a.collect{|a| a[0..1] }
    {
      Port: port,
      Host: "0.0.0.0",
      AccessLog: [],
      SSLCertificate: certificate,
      SSLPrivateKey: OpenSSL::PKey::RSA.new(File.read(SSL_KEY)),
      SSLEnable: true,
      SSLCertName: cert_name
    }
  end

  require "webrick"
  require "webrick/https"
  require "rack"
  require "rack/handler/webrick"

  opts = webrick_opts(4444)

  Rack::Handler::WEBrick.run(app, opts) do |server|
    @server = server
  end
end
