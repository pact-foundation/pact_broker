require 'net/http'
require 'uri'
require 'pact/logging'
require 'pact/consumer/server'
require 'singleton'
require 'pact/mock_service/app'
require 'pact/support/metrics'

module Pact
  module MockService
    class AppManager

      include Pact::Logging

      include Singleton

      def initialize
        @apps_spawned = false
        @app_registrations = []
      end

      def register_mock_service_for(name, url, options = {})
        uri = URI(url)
        raise "Currently only http is supported" unless uri.scheme == 'http'
        uri.port = nil if options[:find_available_port]

        app = Pact::MockService.new(
          name: name,
          log_file: create_log_file(name),
          pact_dir: pact_dir,
          pact_specification_version: options.fetch(:pact_specification_version)
        )

        Pact::Support::Metrics.report_metric("Pact mock server started", "ConsumerTest", "MockServerStarted")
        register(app, uri.host, uri.port)
      end

      def register(app, host, port = nil)
        if port
          existing = existing_app_on_host_and_port(host, port)
          raise "Port #{port} is already being used by #{existing}" if existing and not existing == app
        end
        app_registration = register_app(app, host, port)
        app_registration.spawn
        app_registration.port
      end

      def urls_of_mock_services
        app_registrations.find_all(&:is_a_mock_service?).collect{ |ar| "http://#{ar.host}:#{ar.port}" }
      end

      def kill_all
        app_registrations.find_all(&:spawned?).collect(&:kill)
        @apps_spawned = false
      end

      def clear_all
        kill_all
        @app_registrations = []
      end

      def spawn_all
        app_registrations.find_all(&:not_spawned?).collect(&:spawn)
        @apps_spawned = true
      end

      def app_registered_on?(port)
        app_registrations.any? { |app_registration| app_registration.port == port }
      end

      private

      def existing_app_on_host_and_port(host, port)
        app_registration = registration_on_host_and_port(host, port)
        app_registration ? app_registration.app : nil
      end

      def registration_on_host_and_port(host, port)
        @app_registrations.find { |app_registration| app_registration.port == port && app_registration.host == host }
      end

      def pact_dir
        Pact.configuration.pact_dir
      end

      def create_log_file(service_name)
        FileUtils::mkdir_p(Pact.configuration.log_dir)
        log = File.open(log_file_path(service_name), 'w')
        log.sync = true
        log
      end

      def log_file_path(service_name)
        File.join(Pact.configuration.log_dir, "#{log_file_name(service_name)}.log")
      end

      def log_file_name(service_name)
        lower_case_name = service_name.downcase.gsub(/\s+/, '_')
        if lower_case_name.include?('_service')
          lower_case_name.gsub('_service', '_mock_service')
        else
          lower_case_name + '_mock_service'
        end
      end

      def app_registrations
        @app_registrations
      end

      def register_app(app, host, port)
        app_registration = AppRegistration.new(app: app, host: host, port: port)
        app_registrations << app_registration
        app_registration
      end
    end

    class AppRegistration
      include Pact::Logging
      attr_accessor :host, :port, :app

      def initialize(opts)
        @max_wait = 10
        @port = opts[:port]
        @host = opts[:host]
        @app = opts[:app]
        @spawned = false
      end

      def kill
        logger.debug "Supposed to be stopping"
        @spawned = false
      end

      def not_spawned?
        !spawned?
      end

      def spawned?
        @spawned
      end

      def is_a_mock_service?
        app.is_a?(Pact::MockService::App)
      end

      def to_s
        "#{app} on port #{port}"
      end

      def spawn
        logger.info "Starting app #{self}..."
        @server = Pact::Server.new(app, host, port).boot
        @port = @server.port
        @spawned = true
        logger.info "Started on port #{port}"
      end
    end
  end
end
