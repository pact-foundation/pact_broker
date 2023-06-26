require "pact_broker/logging"
require "pact_broker/errors"

module PactBroker
  module Errors
    class ErrorReporter
      include PactBroker::Logging

      def initialize(api_error_reporters)
        @api_error_reporters = api_error_reporters
      end

      def call error, error_reference, env
        if PactBroker::Errors.reportable_error?(error)
          api_error_reporters.each do | error_reporter |
            begin
              error_reporter.call(error, env: env, error_reference: error_reference)
            rescue StandardError => e
              log_error(e, "Error executing api_error_reporter")
            end
          end
        end
      end

      private

      attr_reader :api_error_reporters
    end
  end
end
