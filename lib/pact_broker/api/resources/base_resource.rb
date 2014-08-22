require 'webmachine'
require 'pact_broker/services'
require 'pact_broker/api/decorators'
require 'pact_broker/logging'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/api/decorators/decorator_context'
require 'pact_broker/json'

module PactBroker

  module Api
    module Resources

      class InvalidJsonError < StandardError ; end

      class ErrorHandler

        include PactBroker::Logging

        def self.handle_exception e, response
          logger.error e
          logger.error e.backtrace
          response.body = {:message => e.message, :backtrace => e.backtrace }.to_json
          response.code = 500
        end
      end

      class BaseResource < Webmachine::Resource

        include PactBroker::Services
        include PactBroker::Api::PactBrokerUrls
        include PactBroker::Logging

        def identifier_from_path
          request.path_info.each_with_object({}) do | pair, hash|
            hash[pair.first] = CGI::unescape(pair.last)
          end
        end

        # This should be called base_url
        def base_url
          request.uri.to_s.gsub(/#{request.uri.path}$/,'')
        end

        def resource_url
          request.uri.to_s
        end

        def decorator_context options = {}
          Decorators::DecoratorContext.new(base_url, resource_url, options)
        end

        def handle_exception e
          PactBroker::Api::Resources::ErrorHandler.handle_exception(e, response)
        end

        def params
          @params ||= JSON.parse(request.body.to_s, {symbolize_names: true}.merge(PACT_PARSING_OPTIONS))
        end

        def set_json_error_message message
          response.headers['Content-Type'] = 'application/json'
          response.body = {error: message}.to_json
        end

        def set_json_validation_error_messages errors
          response.headers['Content-Type'] = 'application/json'
          response.body = {errors: errors}.to_json
        end

        def invalid_json?
          begin
            JSON.parse(request.body.to_s, PACT_PARSING_OPTIONS)
            false
          rescue StandardError => e
            set_json_error_message "Invalid JSON - #{e.message}"
            true
          end
        end

      end
    end
  end
end