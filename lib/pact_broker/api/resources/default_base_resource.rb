require 'webmachine'
require 'pact_broker/api/resources/error_handler'
require 'pact_broker/services'
require 'pact_broker/api/decorators'
require 'pact_broker/logging'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/api/decorators/decorator_context'
require 'pact_broker/json'
require 'pact_broker/pacts/pact_params'
require 'pact_broker/api/resources/authentication'

module PactBroker
  module Api
    module Resources
      class InvalidJsonError < StandardError ; end

      class DefaultBaseResource < Webmachine::Resource
        include PactBroker::Services
        include PactBroker::Api::PactBrokerUrls
        include PactBroker::Api::Resources::Authentication
        include PactBroker::Logging

        attr_accessor :user

        def initialize
          PactBroker.configuration.before_resource.call(self)
        end

        def options
          { 'Access-Control-Allow-Methods' => allowed_methods.join(", ")}
        end

        def known_methods
          super + ['PATCH']
        end

        def finish_request
          PactBroker.configuration.after_resource.call(self)
        end

        def is_authorized?(authorization_header)
          authenticated?(self, authorization_header)
        end

        def forbidden?
          return false if PactBroker.configuration.authorize.nil?
          !PactBroker.configuration.authorize.call(self, {})
        end

        def identifier_from_path
          request.path_info.each_with_object({}) do | pair, hash|
            hash[pair.first] = pair.last === String ? URI.decode(pair.last) : pair.last
          end
        end

        alias_method :path_info, :identifier_from_path

        def base_url
          PactBroker.configuration.base_url || request.base_uri.to_s.chomp('/')
        end

        # See comments for base_url in lib/pact_broker/doc/controllers/app.rb
        def ui_base_url
          PactBroker.configuration.base_url || ''
        end

        def charsets_provided
          [['utf-8', :encode]]
        end

        # We only use utf-8 so leave encoding as it is
        def encode(body)
          body
        end

        def resource_url
          request.uri.to_s.gsub(/\?.*/, '').chomp('/')
        end

        def decorator_context options = {}
          Decorators::DecoratorContext.new(base_url, resource_url, request.env, options)
        end

        def handle_exception e
          PactBroker::Api::Resources::ErrorHandler.call(e, request, response)
        end

        def params
          @params ||= JSON.parse(request.body.to_s, { symbolize_names: true }.merge(PACT_PARSING_OPTIONS)) #Not load! Otherwise it will try to load Ruby classes.
        end

        def params_with_string_keys
          @params_with_string_keys ||= JSON.parse(request.body.to_s, { symbolize_names: false }.merge(PACT_PARSING_OPTIONS))
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request request, path_info
        end

        def set_json_error_message message
          response.headers['Content-Type'] = 'application/hal+json;charset=utf-8'
          response.body = {error: message}.to_json
        end

        def set_json_validation_error_messages errors
          response.headers['Content-Type'] = 'application/hal+json;charset=utf-8'
          response.body = {errors: errors}.to_json
        end

        def request_body
          @request_body ||= request.body.to_s
        end

        def consumer_name
          identifier_from_path[:consumer_name]
        end

        def consumer_version_number
          identifier_from_path[:consumer_version_number]
        end

        def consumer_specified?
          identifier_from_path.key?(:consumer_name)
        end

        def provider_specified?
          identifier_from_path.key?(:provider_name)
        end

        def provider_name
          identifier_from_path[:provider_name]
        end

        def pacticipant_name
          identifier_from_path[:pacticipant_name]
        end

        def pacticipant_specified?
          identifier_from_path.key?(:pacticipant_name)
        end

        def invalid_json?
          begin
            params
            false
          rescue StandardError => e
            logger.info "Error parsing JSON #{e} - #{request_body}"
            set_json_error_message "Error parsing JSON - #{e.message}"
            response.headers['Content-Type'] = 'application/hal+json;charset=utf-8'
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

        def find_pacticipant name, role
          pacticipant_service.find_pacticipant_by_name(name).tap do | pacticipant |
            set_json_error_message("No #{role} with name '#{name}' found") if pacticipant.nil?
          end
        end

        def consumer
          @consumer ||= identifier_from_path[:consumer_name] && find_pacticipant(identifier_from_path[:consumer_name], "consumer")
        end

        def provider
          @provider ||= identifier_from_path[:provider_name] && find_pacticipant(identifier_from_path[:provider_name], "provider")
        end

        def pacticipant
          @pacticipant ||= identifier_from_path[:pacticipant_name] && find_pacticipant(identifier_from_path[:pacticipant_name], "pacticipant")
        end

        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def database_connector
          request.env["pactbroker.database_connector"]
        end
      end
    end
  end
end
