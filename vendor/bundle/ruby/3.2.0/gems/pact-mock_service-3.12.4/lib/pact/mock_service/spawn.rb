require 'pact/mock_service/app'
require 'pact/consumer/server'
require 'pact/consumer/mock_service/set_location'

# Starts a new MockService on a new Thread. Called by the Control Server.

module Pact
  module MockService
    class Spawn

      def self.call consumer, provider, host, port, options
        new(consumer, provider, host, port, options).call
      end

      attr_reader :consumer, :provider, :host, :port, :options

      def initialize consumer, provider, host, port, options
        @consumer = consumer
        @provider = provider
        @host = host
        @port = port
        @options = options
      end

      def call
        mock_service = build_app
        start_mock_service mock_service, port
        puts "Started mock service for #{provider} on #{port}"
        mock_service
      end

      private

      def build_app
        Pact::Consumer::SetLocation.new(mock_service, base_url)
      end

      def mock_service
        Pact::MockService.new(
          log_file: create_log_file,
          log_level: options[:log_level],
          name: name,
          consumer: consumer,
          provider: provider,
          pact_dir: options[:pact_dir] || ".",
          cors_enabled: options[:cors_enabled],
          pact_specification_version: options[:pact_specification_version],
          pactfile_write_mode: options[:pact_file_write_mode]
        )
      end

      def start_mock_service app, port
        Pact::Server.new(app, host, port, ssl: options[:ssl]).boot
      end

      def create_log_file
        FileUtils::mkdir_p options[:log_dir]
        log = File.open(log_file_path, 'w')
        log.sync = true
        log
      end

      def log_file_name
        lower_case_name = name.downcase.gsub(/\s+/, '_')
        if lower_case_name.include?('_service')
          lower_case_name.gsub('_service', '_mock_service')
        else
          lower_case_name + '_mock_service'
        end
      end

      def log_file_path
        File.join(options[:log_dir], "#{log_file_name}.log")
      end

      def base_url
        options[:ssl] ? "https://#{host}:#{port}" : "http://#{host}:#{port}"
      end

      def name
        "#{provider} mock service"
      end
    end

  end
end
