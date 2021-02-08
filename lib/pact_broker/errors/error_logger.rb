require 'pact_broker/configuration'
require 'pact_broker/logging'

module PactBroker
  module Errors
    class ErrorLogger
      include PactBroker::Logging

      # don't need the env, just in case PF needs it
      def self.call(error, error_reference, env = {})
        if log_as_warning?(error)
          logger.warn("Error reference #{error_reference}", error)
        elsif PactBroker::Errors.reportable_error?(error)
          log_error(error, "Error reference #{error_reference}")
        else
          logger.info("Error reference #{error_reference}", error)
        end
      end

      def self.log_as_warning?(error)
        PactBroker.configuration.warning_error_classes.any? { |clazz| error.is_a?(clazz) || error.cause&.is_a?(clazz) }
      end
    end
  end
end
