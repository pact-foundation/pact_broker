# frozen_string_literal: true

module OpenapiFirst
  module Test
    # Helper class to setup tests
    class Configuration
      def initialize
        @minimum_coverage = 100
        @coverage_formatter = Coverage::TerminalFormatter
        @coverage_formatter_options = {}
        @skip_response_coverage = nil
        @skip_coverage = nil
        @response_raise_error = true
        @ignored_unknown_status = [404]
        @report_coverage = true
        @ignore_unknown_requests = false
        @registry = {}
        @apps = {}
      end

      # Register OADs, but don't load them just yet
      # @param [OpenapiFirst::OAD] oad The OAD to register
      # @param [Symbol] as The name to register the OAD under
      def register(oad, as: :default)
        @registry[as] = oad
      end

      # Observe a rack app
      def observe(app, api: :default)
        (@apps[api] ||= []) << app
      end

      attr_accessor :coverage_formatter_options, :coverage_formatter, :response_raise_error,
                    :ignore_unknown_requests
      attr_reader :registry, :apps, :report_coverage, :ignored_unknown_status, :minimum_coverage

      # Configure report coverage
      # @param [Boolean, :warn] value Whether to report coverage or just warn.
      def report_coverage=(value)
        allowed_values = [true, false, :warn]
        unless allowed_values.include?(value)
          raise ArgumentError, "'report_coverage' must be one of #{allowed_values}, but was #{value.inspect}"
        end

        @report_coverage = value
      end

      # @deprecated Use skip_response_coverage, ignored_unknown_status or skip_coverage to configure coverage
      def minimum_coverage=(value)
        warn 'OpenapiFirst::Test::Configuration#minimum_coverage= is deprecated. ' \
             'Use skip_response_coverage, ignored_unknown_status to configure coverage instead.'
        @minimum_coverage = value
      end

      def skip_response_coverage(&block)
        return @skip_response_coverage unless block_given?

        @skip_response_coverage = block
      end

      def skip_coverage(&block)
        return @skip_coverage unless block_given?

        @skip_coverage = block
      end
    end
  end
end
