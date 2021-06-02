require "pact_broker/configuration"
require "pact_broker/error"
require "pact_broker/logging"
require "securerandom"

module PactBroker
  module Errors
    include PactBroker::Logging

    def self.generate_error_reference
      SecureRandom.urlsafe_base64.gsub(/[^a-z]/i, "")[0,10]
    end

    def self.reportable_error?(error)
      !error.is_a?(PactBroker::Error) && !error.is_a?(JSON::JSONError)
    end

    def self.report error, error_reference, request
      PactBroker.configuration.api_error_reporters.each do | error_notifier |
        begin
          error_notifier.call(error, env: request.env, error_reference: error_reference)
        rescue StandardError => e
          log_error(e, "Error executing api_error_reporter")
        end
      end
    end
  end
end
