require 'find_a_port'
require 'pact/mock_service/app'
require 'pact/consumer/mock_service/set_location'
require 'pact/mock_service/run'
require 'pact/mock_service/server/webrick_request_monkeypatch'
require 'pact/specification_version'
require 'pact/support/metrics'
require 'rack/handler/webbrick'

module Pact
  module MockService
    class Run

      def self.call options
        new(options).call
      end

      def initialize options
        @options = options
      end

      def call
        require 'pact/mock_service/app'

        trap(:INT) { call_shutdown_hooks  }
        trap(:TERM) { call_shutdown_hooks }

        require_monkeypatch

        Rack::Handler::WEBrick.run(mock_service, **webbrick_opts)
      end

      private

      attr_reader :options

      def mock_service
        @mock_service ||= begin
          mock_service = Pact::MockService.new(service_options)
          Pact::Support::Metrics.report_metric("Pact mock server started", "ConsumerTest", "MockServerStarted")
          Pact::Consumer::SetLocation.new(mock_service, base_url)
        end
      end

      def call_shutdown_hooks
        unless @shutting_down
          @shutting_down = true
          begin
            mock_service.shutdown
          ensure
            Rack::Handler::WEBrick.shutdown
          end
        end
      end

      def service_options
        # dummy pact_specification_version is needed to stop RequestHandlers blowing up
        service_options = {
          pact_dir: options[:pact_dir],
          log_level: options[:log_level],
          unique_pact_file_names: options[:unique_pact_file_names],
          consumer: options[:consumer],
          provider: options[:provider],
          broker_token: options[:broker_token],
          broker_username: options[:broker_username],
          broker_password: options[:broker_password],
          cors_enabled: options[:cors],
          pact_specification_version: options[:pact_specification_version] || Pact::SpecificationVersion::NIL_VERSION.to_s,
          pactfile_write_mode: options[:pact_file_write_mode],
          stub_pactfile_paths: options[:stub_pactfile_paths]
        }
        service_options[:log_file] = open_log_file if options[:log]
        service_options
      end

      def open_log_file
        FileUtils.mkdir_p File.dirname(options[:log])
        log = File.open(options[:log], 'w')
        log.sync = true
        log
      end

      def webbrick_opts
        # By default, the webrick logs go to $stderr, which then show up as an ERROR
        # log in pact-go, so it was changed to $stdout.
        # $stdout needs sync = true for pact-js to determine the port dynamically from
        # the output (otherwise it does not flush in time for the port to be read)
        $stdout.sync = true
        opts = {
          :Port => port,
          :Host => host,
          :AccessLog => [],
          :Logger => WEBrick::BasicLog.new($stdout)
        }
        opts.merge!({
          :SSLCertificate => OpenSSL::X509::Certificate.new(File.open(options[:sslcert]).read) }) if options[:sslcert]
        opts.merge!({
          :SSLPrivateKey => OpenSSL::PKey::RSA.new(File.open(options[:sslkey]).read) }) if options[:sslkey]
        opts.merge!(ssl_opts) if options[:ssl]
        opts.merge!(options[:webbrick_options]) if options[:webbrick_options]
        opts
      end

      def ssl_opts
        {
          :SSLEnable => true,
          :SSLCertName => [ ["CN", host] ]
        }
      end

      def port
        @port ||= (options[:port] || FindAPort.available_port).to_i
      end

      def host
        @host ||= options[:host] || "localhost"
      end

      def base_url
        options[:ssl] ? "https://#{host}:#{port}" : "http://#{host}:#{port}"
      end

      def require_monkeypatch
        require options[:monkeypatch] if options[:monkeypatch]
      end
    end
  end
end
