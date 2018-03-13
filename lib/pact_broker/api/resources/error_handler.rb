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
          response.body = {:message => e.message, :backtrace => e.backtrace }.to_json
          report e, request
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
