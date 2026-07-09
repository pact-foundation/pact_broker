require "semantic_logger"
require "pact_broker/error"

module PactBroker
  module Logging
    # Adds semantic_logger's :open_telemetry appender when configured, without
    # taking a hard dependency on the OpenTelemetry gems.
    class OpenTelemetryAppenderSetup
      def self.call(runtime_configuration)
        new(runtime_configuration).call
      end

      def initialize(runtime_configuration)
        @runtime_configuration = runtime_configuration
      end

      # Returns the added (or already-present) appender, or nil if none was added.
      def call
        case @runtime_configuration.log_otel_enabled
        when false
          nil
        when true
          unless otel_available?
            raise PactBroker::ConfigurationError,
              "log_otel_enabled is set to true but the opentelemetry-logs-sdk gem could not be loaded. " \
              "Add it to your Gemfile, or set log_otel_enabled to auto/false."
          end
          add_appender(warn_if_no_provider: true)
        else # :auto
          add_appender(warn_if_no_provider: false) if otel_available? && otel_provider_configured?
        end
      end

      private

      def add_appender(warn_if_no_provider:)
        existing = existing_otel_appender
        return existing if existing

        if warn_if_no_provider && !otel_provider_configured?
          SemanticLogger["pact-broker"].warn(
            "log_otel_enabled is true but no OpenTelemetry LoggerProvider is configured; " \
            "OTel log records may be dropped."
          )
        end

        SemanticLogger.add_appender(appender: :open_telemetry)
      end

      def existing_otel_appender
        return nil unless defined?(SemanticLogger::Appender::OpenTelemetry)

        SemanticLogger.appenders.find { |appender| appender.is_a?(SemanticLogger::Appender::OpenTelemetry) }
      end

      def otel_available?
        require "opentelemetry-logs-sdk"
        defined?(OpenTelemetry::Logs) ? true : false
      rescue LoadError
        false
      end

      def otel_provider_configured?
        return false unless defined?(OpenTelemetry)

        # A no-op / proxy provider means no real logs pipeline is configured.
        OpenTelemetry.logger_provider.class.name.to_s.start_with?("OpenTelemetry::SDK::Logs")
      rescue StandardError
        false
      end
    end
  end
end
