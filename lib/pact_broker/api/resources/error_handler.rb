require 'pact_broker/configuration'
require 'securerandom'

module PactBroker
  module Api
    module Resources
      class ErrorHandler

        include PactBroker::Logging

        def self.call e, request, response
          error_reference = generate_error_reference
          if reportable?(e)
            log_error(e, "Error reference #{error_reference}")
            report(e, error_reference, request)
          else
            logger.info "Error reference #{error_reference} - #{e.class} #{e.message}\n#{e.backtrace.join("\n")}"
          end
          response.body = response_body_hash(e, error_reference).to_json
        end

        def self.generate_error_reference
          SecureRandom.urlsafe_base64.gsub(/[^a-z]/i, '')[0,10]
        end

        def self.reportable?(e)
          !e.is_a?(PactBroker::Error) && !e.is_a?(JSON::GeneratorError)
        end

        def self.display_message(e, error_reference)
          if PactBroker.configuration.show_backtrace_in_error_response?
            e.message || obfuscated_error_message(error_reference)
          else
           reportable?(e) ? obfuscated_error_message(error_reference) : e.message
          end
        end

        def self.obfuscated_error_message error_reference
          "An error has occurred. The details have been logged with the reference #{error_reference}"
        end

        def self.response_body_hash e, error_reference
          response_body = {
            error: {
              message: display_message(e, error_reference),
              reference: error_reference
            }
          }
          if PactBroker.configuration.show_backtrace_in_error_response?
            response_body[:error][:backtrace] = e.backtrace
          end
          response_body
        end

        def self.report e, error_reference, request
          PactBroker.configuration.api_error_reporters.each do | error_notifier |
            begin
              error_notifier.call(e, env: request.env, error_reference: error_reference)
            rescue StandardError => e
              log_error(e, "Error executing api_error_reporter")
            end
          end
        end
      end
    end
  end
end
