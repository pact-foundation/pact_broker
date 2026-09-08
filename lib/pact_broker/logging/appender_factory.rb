# frozen_string_literal: true
require "semantic_logger"
require "semantic_logger/formatters/short"
require "pact_broker/error"

module PactBroker
  module Logging
    # Builds one appender from one log_appenders entry.
    class AppenderFactory
      SUGAR_KEYS = [:stream, :format, :enabled].freeze
      VALID_STREAMS = [:stdout, :stderr, :file].freeze
      VALID_FORMATS = [:default, :color, :json, :logfmt, :one_line, :short, :raw, :auto].freeze
      DEFAULT_LOG_FILE_NAME = "pact_broker.log"

      def self.call(entry, index:, log_dir:)
        new(entry, index: index, log_dir: log_dir).call
      end

      def initialize(entry, index:, log_dir:)
        @entry = entry
        @index = index
        @log_dir = log_dir
      end

      def call
        return nil if enabled == false

        add_appender
      end

      private

      attr_reader :entry, :index, :log_dir

      def add_appender
        SemanticLogger.add_appender(**appender_options)
      rescue LoadError => e
        return nil if enabled == :auto

        raise_configuration_error(e.message)
      rescue StandardError => e
        raise_configuration_error("#{e.class}: #{e.message}")
      end

      def raise_configuration_error(message)
        raise PactBroker::ConfigurationError,
          "log_appenders entry #{index} could not be configured: #{message}"
      end

      def appender_options
        options = entry.reject { | key, _ | SUGAR_KEYS.include?(key) }
        options = options.merge(stream_options) if entry.key?(:stream)
        formatter = resolve_format
        options[:formatter] = formatter if formatter
        options
      end

      def stream_options
        case entry[:stream]
        when :stdout then { io: $stdout }
        when :stderr then { io: $stderr }
        when :file then { file_name: entry[:file_name] || default_file_name }
        else {}
        end
      end

      def default_file_name
        File.join(log_dir.to_s, DEFAULT_LOG_FILE_NAME)
      end

      def resolve_format
        case entry[:format]
        when nil then nil
        when :auto then tty? ? :color : :json
        else entry[:format]
        end
      end

      def tty?
        case entry[:stream]
        when :stdout then $stdout.tty?
        when :stderr then $stderr.tty?
        else false
        end
      end

      def enabled
        entry.fetch(:enabled, true)
      end
    end
  end
end
