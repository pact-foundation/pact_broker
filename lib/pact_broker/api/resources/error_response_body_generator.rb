require 'pact_broker/configuration'

module PactBroker
  module Api
    module Resources
      class ErrorResponseBodyGenerator
        include PactBroker::Logging

        # env not needed, just passing in in case PF ever needs it
        def self.call error, error_reference, env = {}
          response_body_hash(error, error_reference).to_json
        end

        def self.display_message(error, obfuscated_message)
          if PactBroker.configuration.show_backtrace_in_error_response?
            error.message || obfuscated_message
          else
           PactBroker::Errors.reportable_error?(error) ? obfuscated_message : error.message
          end
        end

        def self.obfuscated_error_message(error_reference)
          "An error has occurred. The details have been logged with the reference #{error_reference}"
        end

        def self.response_body_hash(error, error_reference)
          response_body = {
            error: {
              message: display_message(error, obfuscated_error_message(error_reference)),
              reference: error_reference
            }
          }
          if PactBroker.configuration.show_backtrace_in_error_response?
            response_body[:error][:backtrace] = error.backtrace
          end
          response_body
        end
      end
    end
  end
end
