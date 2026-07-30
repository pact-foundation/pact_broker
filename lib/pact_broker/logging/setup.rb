# frozen_string_literal: true
require "fileutils"
require "semantic_logger"
require "pact_broker/logging/appender_entries"
require "pact_broker/logging/appender_factory"
require "pact_broker/logging/context"
require "pact_broker/logging/context/trace_context"

module PactBroker
  module Logging
    # Applies the runtime configuration to SemanticLogger.
    #
    # Ordering matters, and is constrained from both ends. Deprecation warnings
    # concern the settings that decide where a warning can go, so they are
    # buffered by AppenderEntries and flushed here only once the appenders exist
    # and the context pipeline is installed. Flushing earlier would either lose
    # the warnings entirely or emit them without their context tags.
    class Setup
      DEFAULT_LOGGER_NAME = "pact-broker"

      class << self
        # Appenders added by the most recent call, so that a second call replaces
        # them instead of accumulating duplicates.
        def added_appenders
          @added_appenders ||= []
        end

        def call(runtime_configuration)
          new(runtime_configuration).call
        end

        # Used by PactBroker::Configuration#logger= when a custom logger takes over.
        def remove_appenders
          added_appenders.each { | appender | SemanticLogger.remove_appender(appender) }
          @added_appenders = []
          nil
        end

        # Test seam: forget what we added without touching SemanticLogger.
        def reset!
          @added_appenders = []
          @shutdown_flush_registered = false
          nil
        end

        def register_shutdown_flush
          return if @shutdown_flush_registered

          @shutdown_flush_registered = true
          # SemanticLogger registers no at_exit of its own, so buffered records
          # would be lost on shutdown.
          at_exit { SemanticLogger.flush }
        end
      end

      def initialize(runtime_configuration)
        @runtime_configuration = runtime_configuration
      end

      # Returns the appenders that were added.
      def call
        self.class.remove_appenders

        SemanticLogger.default_level = runtime_configuration.log_level
        apply_global_metadata

        resolved = AppenderEntries.call(runtime_configuration)
        appenders = add_appenders(resolved)

        install_context_pipeline
        self.class.register_shutdown_flush
        flush_warnings(resolved.warnings, appenders)

        appenders
      end

      private

      attr_reader :runtime_configuration

      def apply_global_metadata
        SemanticLogger.application = runtime_configuration.log_application if runtime_configuration.log_application
        SemanticLogger.environment = runtime_configuration.log_environment if runtime_configuration.log_environment
      end

      def add_appenders(resolved)
        ensure_log_dir_exists(resolved.entries)

        appenders = resolved.entries.each_with_index.collect do | entry, index |
          AppenderFactory.call(entry, index: index, log_dir: runtime_configuration.log_dir)
        end.compact

        self.class.added_appenders.concat(appenders)
        appenders
      rescue PactBroker::ConfigurationError
        # No appender to log through, and the operator needs to see any buffered
        # warnings alongside the failure to make sense of it.
        print_warnings_to_stderr(resolved.warnings)
        raise
      end

      def ensure_log_dir_exists(entries)
        return unless entries.any? { | entry | entry[:stream] == :file && entry[:file_name].nil? }

        FileUtils.mkdir_p(runtime_configuration.log_dir)
      end

      def install_context_pipeline
        # Both calls are idempotent: SemanticLogger deduplicates subscribers by
        # object identity, and register_provider replaces by name.
        SemanticLogger.on_log(Context)
        Context.register_provider(:trace, Context::TraceContext)
      end

      def flush_warnings(warnings, appenders)
        return if warnings.empty?

        if appenders.empty?
          print_warnings_to_stderr(warnings)
        else
          logger = SemanticLogger[DEFAULT_LOGGER_NAME]
          warnings.each { | warning | logger.warn(warning) }
        end
      end

      def print_warnings_to_stderr(warnings)
        warnings.each { | warning | $stderr.puts("WARN: #{warning}") }
      end
    end
  end
end
