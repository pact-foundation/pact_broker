require 'thor'

module Pact
  module MockService
    class CLI < Thor
      def self.exit_on_failure? # Thor 1.0 deprecation guard
        false
      end

      PACT_FILE_WRITE_MODE_DESC = "`overwrite` or `merge`. Use `merge` when running multiple mock service instances in parallel for the same consumer/provider pair." +
      " Ensure the pact file is deleted before running tests when using this option so that interactions deleted from the code are not maintained in the file."

      desc 'service', "Start a mock service. If the consumer, provider and pact-dir options are provided, the pact will be written automatically on shutdown (INT)."
      method_option :consumer, desc: "Consumer name"
      method_option :provider, desc: "Provider name"
      method_option :port, aliases: "-p", desc: "Port on which to run the service"
      method_option :host, aliases: "-h", desc: "Host on which to bind the service", default: 'localhost'
      method_option :pact_dir, aliases: "-d", desc: "Directory to which the pacts will be written"
      method_option :pact_file_write_mode, aliases: "-m", desc: PACT_FILE_WRITE_MODE_DESC, type: :string, default: 'overwrite'
      method_option :pact_specification_version, aliases: "-i", desc: "The pact specification version to use when writing the pact. Note that only versions 1 and 2 are currently supported.", default: '2'
      method_option :log, aliases: "-l", desc: "File to which to log output"
      method_option :log_level, desc: "Log level. Options are DEBUG INFO WARN ERROR", default: "DEBUG"
      method_option :cors, aliases: "-o", desc: "Support browser security in tests by responding to OPTIONS requests and adding CORS headers to mocked responses"
      method_option :ssl, desc: "Use a self-signed SSL cert to run the service over HTTPS", type: :boolean, default: false
      method_option :sslcert, desc: "Specify the path to the SSL cert to use when running the service over HTTPS"
      method_option :sslkey, desc: "Specify the path to the SSL key to use when running the service over HTTPS"
      method_option :monkeypatch, hide: true

      def service
        require_common_dependencies
        require 'pact/mock_service/run'
        Run.(options)
      end

      desc 'control', "Run a Pact mock service control server."
      method_option :port, aliases: "-p", desc: "Port on which to run the service"
      method_option :host, aliases: "-h", desc: "Host on which to bind the service", default: 'localhost'
      method_option :pact_dir, aliases: "-d", desc: "Directory to which the pacts will be written"
      method_option :log_dir, aliases: "-l", desc: "File to which to log output"
      method_option :log_level, desc: "Log level. Options are DEBUG INFO WARN ERROR", default: "DEBUG"
      method_option :pact_file_write_mode, aliases: "-m", desc: PACT_FILE_WRITE_MODE_DESC, type: :string, default: 'overwrite'
      method_option :pact_specification_version, aliases: "-i", desc: "The pact specification version to use when writing the pact. Note that only versions 1 and 2 are currently supported.", default: '2'
      method_option :cors, aliases: "-o", desc: "Support browser security in tests by responding to OPTIONS requests and adding CORS headers to mocked responses"
      method_option :ssl, desc: "Use a self-signed SSL cert to run the service over HTTPS", type: :boolean, default: false
      method_option :sslcert, desc: "Specify the path to the SSL cert to use when running the service over HTTPS"
      method_option :sslkey, desc: "Specify the path to the SSL key to use when running the service over HTTPS"

      def control
        require_common_dependencies
        require 'pact/mock_service/control_server/run'
        ControlServer::Run.(options)
      end

      desc 'start', "Start a mock service. If the consumer, provider and pact-dir options are provided, the pact will be written automatically on shutdown (INT)."
      method_option :consumer, desc: "Consumer name"
      method_option :provider, desc: "Provider name"
      method_option :port, aliases: "-p", default: '1234', desc: "Port on which to run the service"
      method_option :host, aliases: "-h", desc: "Host on which to bind the service", default: 'localhost'
      method_option :pact_dir, aliases: "-d", desc: "Directory to which the pacts will be written"
      method_option :pact_file_write_mode, aliases: "-m", desc: PACT_FILE_WRITE_MODE_DESC, type: :string, default: 'overwrite'
      method_option :pid_dir, desc: "PID dir", default: 'tmp/pids'
      method_option :log, aliases: "-l", desc: "File to which to log output"
      method_option :log_level, desc: "Log level. Options are DEBUG INFO WARN ERROR", default: "DEBUG"
      method_option :pact_specification_version, aliases: "-i", desc: "The pact specification version to use when writing the pact. Note that only versions 1 and 2 are currently supported.", default: '2'
      method_option :cors, aliases: "-o", desc: "Support browser security in tests by responding to OPTIONS requests and adding CORS headers to mocked responses"
      method_option :ssl, desc: "Use a self-signed SSL cert to run the service over HTTPS", type: :boolean, default: false
      method_option :sslcert, desc: "Specify the path to the SSL cert to use when running the service over HTTPS"
      method_option :sslkey, desc: "Specify the path to the SSL key to use when running the service over HTTPS"
      method_option :monkeypatch, hide: true

      def start
        require_common_dependencies
        start_server(mock_service_pidfile) do
          service
        end
      end

      desc 'stop', "Stop a Pact mock service"
      method_option :port, aliases: "-p", desc: "Port of the service to stop", default: '1234', required: true
      method_option :pid_dir, desc: "PID dir, defaults to tmp/pids", default: "tmp/pids"

      def stop
        require_common_dependencies
        mock_service_pidfile.kill_process
      end

      desc 'restart', "Start or restart a mock service. If the consumer, provider and pact-dir options are provided, the pact will be written automatically on shutdown (INT)."
      method_option :consumer, desc: "Consumer name"
      method_option :provider, desc: "Provider name"
      method_option :port, aliases: "-p", default: '1234', desc: "Port on which to run the service"
      method_option :host, aliases: "-h", desc: "Host on which to bind the service", default: 'localhost'
      method_option :pact_dir, aliases: "-d", desc: "Directory to which the pacts will be written"
      method_option :pact_file_write_mode, aliases: "-m", desc: PACT_FILE_WRITE_MODE_DESC, type: :string, default: 'overwrite'
      method_option :pid_dir, desc: "PID dir", default: 'tmp/pids'
      method_option :log, aliases: "-l", desc: "File to which to log output"
      method_option :log_level, desc: "Log level. Options are DEBUG INFO WARN ERROR", default: "DEBUG"
      method_option :pact_specification_version, aliases: "-i", desc: "The pact specification version to use when writing the pact. Note that only versions 1 and 2 are currently supported.", default: '2'
      method_option :cors, aliases: "-o", desc: "Support browser security in tests by responding to OPTIONS requests and adding CORS headers to mocked responses"
      method_option :ssl, desc: "Use a self-signed SSL cert to run the service over HTTPS", type: :boolean, default: false
      method_option :sslcert, desc: "Specify the path to the SSL cert to use when running the service over HTTPS"
      method_option :sslkey, desc: "Specify the path to the SSL key to use when running the service over HTTPS"

      def restart
        require_common_dependencies
        restart_server(mock_service_pidfile) do
          service
        end
      end

      desc 'control-start', "Start a Pact mock service control server."
      method_option :port, aliases: "-p", desc: "Port on which to run the service", default: '1234'
      method_option :host, aliases: "-h", desc: "Host on which to bind the service", default: 'localhost'
      method_option :log_dir, aliases: "-l", desc: "File to which to log output", default: "log"
      method_option :log_level, desc: "Log level. Options are DEBUG INFO WARN ERROR", default: "DEBUG"
      method_option :pact_file_write_mode, aliases: "-m", desc: PACT_FILE_WRITE_MODE_DESC, type: :string, default: 'overwrite'
      method_option :pact_specification_version, aliases: "-i", desc: "The pact specification version to use when writing the pact", default: '2'
      method_option :pid_dir, desc: "PID dir", default: "tmp/pids"
      method_option :cors, aliases: "-o", desc: "Support browser security in tests by responding to OPTIONS requests and adding CORS headers to mocked responses"
      method_option :ssl, desc: "Use a self-signed SSL cert to run the service over HTTPS", type: :boolean, default: false
      method_option :sslcert, desc: "Specify the path to the SSL cert to use when running the service over HTTPS"
      method_option :sslkey, desc: "Specify the path to the SSL key to use when running the service over HTTPS"
      method_option :pact_dir, aliases: "-d", desc: "Directory to which the pacts will be written", default: "."

      def control_start
        require_common_dependencies
        start_server(control_server_pidfile) do
          control
        end
      end

      desc 'control-stop', "Stop a Pact mock service control server."
      method_option :port, aliases: "-p", desc: "Port of control server to stop", default: "1234"
      method_option :pid_dir, desc: "PID dir, defaults to tmp/pids", default: "tmp/pids"

      def control_stop
        require_common_dependencies
        control_server_pidfile.kill_process
      end

      desc 'control-restart', "Start a Pact mock service control server."
      method_option :port, aliases: "-p", desc: "Port on which to run the service", default: '1234'
      method_option :host, aliases: "-h", desc: "Host on which to bind the service", default: 'localhost'
      method_option :log_dir, aliases: "-l", desc: "File to which to log output", default: "log"
      method_option :log_level, desc: "Log level. Options are DEBUG INFO WARN ERROR", default: "DEBUG"
      method_option :pact_dir, aliases: "-d", desc: "Directory to which the pacts will be written", default: "."
      method_option :pact_file_write_mode, aliases: "-m", desc: PACT_FILE_WRITE_MODE_DESC, type: :string, default: 'overwrite'
      method_option :pact_specification_version, aliases: "-i", desc: "The pact specification version to use when writing the pact. Note that only versions 1 and 2 are currently supported.", default: '2'
      method_option :pid_dir, desc: "PID dir", default: "tmp/pids"
      method_option :cors, aliases: "-o", desc: "Support browser security in tests by responding to OPTIONS requests and adding CORS headers to mocked responses"
      method_option :ssl, desc: "Use a self-signed SSL cert to run the service over HTTPS", type: :boolean, default: false
      method_option :sslcert, desc: "Specify the path to the SSL cert to use when running the service over HTTPS"
      method_option :sslkey, desc: "Specify the path to the SSL key to use when running the service over HTTPS"

      def control_restart
        require_common_dependencies
        restart_server(control_server_pidfile) do
          control
        end
      end

      desc 'version', "Show the pact-mock-service gem version"

      def version
        require 'pact/mock_service/version.rb'
        puts Pact::MockService::VERSION
      end

      default_task :service

      no_commands do

        def require_common_dependencies
          require 'webrick/https'
          require 'rack/handler/webbrick'
          require 'fileutils'
          require 'pact/mock_service/server/wait_for_server_up'
          require 'pact/mock_service/cli/pidfile'
          require 'socket'
        end

        def control_server_pidfile
          Pidfile.new(pid_dir: options[:pid_dir], name: control_pidfile_name)
        end

        def mock_service_pidfile
          Pidfile.new(pid_dir: options[:pid_dir], name: mock_service_pidfile_name)
        end

        def mock_service_pidfile_name
          "mock-service-#{options[:port]}.pid"
        end

        def control_pidfile_name
          "mock-service-control-#{options[:port]}.pid"
        end

        def start_server pidfile
          require 'pact/mock_service/server/spawn'
          Pact::MockService::Server::Spawn.(pidfile, options[:host], options[:port], options[:ssl]) do
            yield
          end
        end

        def restart_server pidfile
          require 'pact/mock_service/server/respawn'
          Pact::MockService::Server::Respawn.(pidfile, options[:host], options[:port], options[:ssl]) do
            yield
          end
        end
      end
    end
  end
end
