require 'uri'
require 'net/http'
require 'rack'
require 'rack/handler/webbrick'

# Copied shamelessly from Capybara
# Used to run a mock service in a new thread when started by the AppManager or the ControlServer

module Pact
  class Server
    class Middleware
      attr_accessor :error

      def initialize(app)
        @app = app
      end

      def call(env)
        if env["PATH_INFO"] == "/__identify__"
          [200, {}, [@app.object_id.to_s]]
        else
          begin
            @app.call(env)
          rescue StandardError => e
            @error = e unless @error
            raise e
          end
        end
      end
    end

    class << self
      def ports
        @ports ||= {}
      end
    end

    attr_reader :app, :host, :port, :options

    def initialize(app, host, port, options = {})
      @app = app
      @middleware = Middleware.new(@app)
      @server_thread = nil
      @host = host
      @port = port
      @options = options
    end

    def reset_error!
      @middleware.error = nil
    end

    def error
      @middleware.error
    end

    def responsive?
      return false if @server_thread && @server_thread.join(0)
      res = get_identity
      if res.is_a?(Net::HTTPSuccess) or res.is_a?(Net::HTTPRedirection)
        return res.body == @app.object_id.to_s
      end
    rescue SystemCallError
      return false
    rescue EOFError
      return false
    end

    def run_default_server(app, port)
      Rack::Handler::WEBrick.run(app, **webrick_opts) do |server|
        @port = server[:Port]
      end
    end

    def get_identity
      return false unless @port
      http = Net::HTTP.new host, @port
      if options[:ssl]
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http.get('/__identify__')
    end

    def webrick_opts
      opts = { Host: host.nil? ? 'localhost' : host, Port: port.nil? ? 0 : port, AccessLog: [], Logger: WEBrick::Log::new(nil, 0) }
      opts.merge!({
        :SSLCertificate => OpenSSL::X509::Certificate.new(File.open(options[:sslcert]).read) }) if options[:sslcert]
      opts.merge!({
        :SSLPrivateKey => OpenSSL::PKey::RSA.new(File.open(options[:sslkey]).read) }) if options[:sslkey]
      opts.merge!(ssl_opts) if options[:ssl]
      opts
    end

    def ssl_opts
      { SSLEnable: true, SSLCertName: [ ["CN", host] ] }
    end

    def boot
      unless responsive?
        @server_thread = Thread.new { run_default_server(@middleware, @port) }
        Timeout.timeout(60) { @server_thread.join(0.1) until responsive? }
      end
    rescue Timeout::Error
      raise "Rack application timed out during boot"
    else
      Pact::Server.ports[@app.object_id] = @port
      self
    end
  end
end
