# frozen_string_literal: true
require "webmachine"
require "pact_broker/services"
require "pact_broker/api/decorators"
require "pact_broker/logging"
require "pact_broker/api/pact_broker_urls"
require "pact_broker/json"
require "pact_broker/pacts/pact_params"
require "pact_broker/api/resources/authentication"
require "pact_broker/api/resources/authorization"
require "pact_broker/errors"

module PactBroker
  module Api
    module Resources
      class InvalidJsonError < PactBroker::Error ; end

      class DefaultBaseResource < Webmachine::Resource
        include PactBroker::Services
        include PactBroker::Api::PactBrokerUrls
        include PactBroker::Api::Resources::Authentication
        include PactBroker::Api::Resources::Authorization

        include PactBroker::Logging

        attr_accessor :user

        def initialize
          PactBroker.configuration.before_resource.call(self)
          application_context.before_resource&.call(self)
        end

        def options
          { "Access-Control-Allow-Methods" => allowed_methods.join(", ")}
        end

        def known_methods
          super + ["PATCH"]
        end

        def finish_request
          application_context.after_resource&.call(self)
          PactBroker.configuration.after_resource.call(self)
        end

        def is_authorized?(authorization_header)
          authenticated?(self, authorization_header)
        end

        def forbidden?
          if application_context.resource_authorizer
            !application_context.resource_authorizer.call(self)
          elsif PactBroker.configuration.authorize
            !PactBroker.configuration.authorize.call(self, {})
          else
            false
          end
        end

        # The path_info segments aren't URL decoded
        def identifier_from_path
          @identifier_from_path ||= request.path_info.each_with_object({}) do | (key, value), hash|
            if value.is_a?(String)
              hash[key] = URI.decode(value)
            elsif value.is_a?(Symbol) || value.is_a?(Numeric)
              hash[key] = value
            end
          end
        end

        alias_method :path_info, :identifier_from_path

        def base_url
          # Have to use something for the base URL here - we can't use an empty string as we can in the UI.
          # Can't work out if cache poisoning is a vulnerability for APIs or not.
          # Using the request base URI as a fallback if the base_url is not configured may be a vulnerability,
          # but the documentation recommends that the
          # base_url should be set in the configuration to mitigate this.
          request.env["pactbroker.base_url"] || request.base_uri.to_s.chomp("/")
        end

        # See comments for base_url in lib/pact_broker/doc/controllers/app.rb
        def ui_base_url
          request.env["pactbroker.base_url"] || ""
        end

        def charsets_provided
          [["utf-8", :encode]]
        end

        # We only use utf-8 so leave encoding as it is
        def encode(body)
          body
        end

        def resource_url
          request.uri.to_s.gsub(/\?.*/, "").chomp("/")
        end

        def decorator_context options = {}
          application_context.decorator_context_creator.call(self, options)
        end

        def decorator_options options = {}
          { user_options: decorator_context(options) }
        end

        def handle_exception(error)
          error_reference = PactBroker::Errors.generate_error_reference
          application_context.error_logger.call(error, error_reference, request.env)
          if PactBroker::Errors.reportable_error?(error)
            PactBroker::Errors.report(error, error_reference, request.env)
          end
          response.body = application_context.error_response_body_generator.call(error, error_reference, request.env)
        end

        # rubocop: disable Metrics/CyclomaticComplexity
        def params(options = {})
          return options[:default] if options.key?(:default) && request_body.empty?

          symbolize_names = !options.key?(:symbolize_names) || options[:symbolize_names]
          if symbolize_names
            @params_with_symbol_keys ||= JSON.parse(request_body, { symbolize_names: true }.merge(PACT_PARSING_OPTIONS)) #Not load! Otherwise it will try to load Ruby classes.
          else
            @params_with_string_keys ||= JSON.parse(request_body, { symbolize_names: false }.merge(PACT_PARSING_OPTIONS)) #Not load! Otherwise it will try to load Ruby classes.
          end
        rescue JSON::JSONError => e
          raise InvalidJsonError.new("Error parsing JSON - #{e.message}")
        end
        # rubocop: enable Metrics/CyclomaticComplexity

        def params_with_string_keys
          params(symbolize_names: false)
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request request, identifier_from_path
        end

        def set_json_error_message message
          response.headers["Content-Type"] = "application/hal+json;charset=utf-8"
          response.body = { error: message }.to_json
        end

        def set_json_validation_error_messages errors
          response.headers["Content-Type"] = "application/hal+json;charset=utf-8"
          response.body = { errors: errors }.to_json
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

        def pacticipant_version_number
          identifier_from_path[:pacticipant_version_number]
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
            response.headers["Content-Type"] = "application/hal+json;charset=utf-8"
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

        # Not necessarily an existing integration
        def integration
          if consumer_specified? && provider_specified?
            OpenStruct.new(consumer: consumer, provider: provider)
          else
            nil
          end
        end

        def database_connector
          request.env["pactbroker.database_connector"]
        end

        def application_context
          request.path_info[:application_context]
        end

        def decorator_class(name)
          application_context.decorator_configuration.class_for(name)
        end

        def api_contract_class(name)
          application_context.api_contract_configuration.class_for(name)
        end

        def schema
          nil
        end

        def validation_errors_for_schema?(schema_to_use = schema, params_to_validate = params)
          if (errors = schema_to_use.call(params_to_validate)).any?
            set_json_validation_error_messages(errors)
            true
          else
            false
          end
        end

        def malformed_request_for_json_with_schema?(schema_to_use = schema, params_to_validate = params)
          invalid_json? || validation_errors_for_schema?(schema_to_use, params_to_validate)
        end
      end
    end
  end
end
