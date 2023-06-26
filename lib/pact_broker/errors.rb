require "securerandom"

module PactBroker
  module Errors
    def self.generate_error_reference
      SecureRandom.urlsafe_base64.gsub(/[^a-z]/i, "")[0,10]
    end

    # Return true if the error is one that should be reported to an external bug tracking system
    # @return [Boolean]
    def self.reportable_error?(error)
      error.is_a?(PactBroker::TestError) || (!error.is_a?(PactBroker::Error) && !error.is_a?(JSON::JSONError))
    end
  end
end
