require 'webmachine'
require 'pact_broker/services'
require 'pact_broker/api/decorators'
require 'pact_broker/logging'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/api/decorators/decorator_context'
require 'pact_broker/json'
require 'pact_broker/pacts/pact_params'

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
        end
      end

      class BaseResource < Webmachine::Resource

        include PactBroker::Services
        include PactBroker::Api::PactBrokerUrls
        include PactBroker::Logging

        def initialize
          PactBroker.configuration.before_resource.call(self)
        end

        def finish_request
          PactBroker.configuration.after_resource.call(self)
        end

        def identifier_from_path
          request.path_info.each_with_object({}) do | pair, hash|
            hash[pair.first] = pair.last === String ? URI.decode(pair.last) : pair.last
          end
        end

        alias_method :path_info, :identifier_from_path

        def base_url
          request.base_uri.to_s.chomp('/')
        end

        def charsets_provided
          [['utf-8', :encode]]
        end

        # We only use utf-8 so leave encoding as it is
        def encode(body)
          body
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

        def params_with_string_keys
          JSON.parse(request.body.to_s, {symbolize_names: false}.merge(PACT_PARSING_OPTIONS))
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request request, path_info
        end

        def set_json_error_message message
          response.headers['Content-Type'] = 'application/json;charset=utf-8'
          response.body = {error: message}.to_json
        end

        def set_json_validation_error_messages errors
          response.headers['Content-Type'] = 'application/json;charset=utf-8'
          response.body = {errors: errors}.to_json
        end

        def request_body
          @request_body ||= request.body.to_s
        end

        def consumer_name
          identifier_from_path[:consumer_name]
        end

        def provider_name
          identifier_from_path[:provider_name]
        end

        def pacticipant_name
          identifier_from_path[:pacticipant_name]
        end

        def invalid_json?
          begin
            JSON.parse(request_body, PACT_PARSING_OPTIONS) #Not load! Otherwise it will try to load Ruby classes.
            false
          rescue StandardError => e
            logger.error "Error parsing JSON #{e} - #{request_body}"
            set_json_error_message "Error parsing JSON - #{e.message}"
            response.headers['Content-Type'] = 'application/json;charset=utf-8'
            true
          end
        end

        def validation_errors? model
          if (errors = model.validate).any?
            set_json_validation_error_messages errors
            true
          else
            false
          end
        end

        def contract_validation_errors? contract, params
          if (invalid = !contract.validate(params))
            set_json_validation_error_messages contract.errors.messages
          end
          invalid
        end

      end
    end
  end
end
