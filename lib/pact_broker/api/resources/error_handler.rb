require 'webmachine/convert_request_to_rack_env'
require 'pact_broker/configuration'

module PactBroker
  module Api
    module Resources
      class ErrorHandler

        include PactBroker::Logging

        def self.call e, request, response
          logger.error e
          logger.error e.backtrace
          response_body = { :message => e.message }
          if PactBroker.configuration.show_backtrace_in_error_response?
            response_body[:backtrace] = e.backtrace
          end
          response.body = response_body.to_json
          report(e, request) if reportable?(e)
        end

        def self.reportable? e
          !e.is_a?(PactBroker::Error)
        end

        def self.report e, request
          PactBroker.configuration.api_error_reporters.each do | error_notifier |
            begin
              error_notifier.call(e, env: Webmachine::ConvertRequestToRackEnv.call(request))
            rescue StandardError => e
              log_error(e, "Error executing api_error_reporter")
            end
          end
        end
      end
    end
  end
end
