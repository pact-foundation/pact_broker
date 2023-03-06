# frozen_string_literal: true
require "pact_broker/configuration"
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
require "pact_broker/api/resources/error_handling_methods"
require "pact_broker/api/contracts/utf_8_validation"

module PactBroker
  module Api
    module Resources
      class InvalidJsonError < PactBroker::Error ; end
      class NonUTF8CharacterFound < PactBroker::Error ; end

      class BaseResource < Webmachine::Resource
        include PactBroker::Services
        include PactBroker::Api::PactBrokerUrls
        include PactBroker::Api::Resources::Authentication
        include PactBroker::Api::Resources::Authorization
        include PactBroker::Api::Resources::ErrorHandlingMethods
        include PactBroker::Api::Contracts::UTF8Validation

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

        def malformed_request?
          content_type_is_json_but_invalid_json_provided?
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
              hash[key] = Webmachine::Dispatcher::Route.rfc3986_percent_decode(value)
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

        # rubocop: disable Metrics/CyclomaticComplexity
        def params(options = {})
          return options[:default] if options.key?(:default) && request_body.empty?

          symbolize_names = !options.key?(:symbolize_names) || options[:symbolize_names]
          parsed_params = if symbolize_names
                            @params_with_symbol_keys ||= JSON.parse(request_body, { symbolize_names: true }.merge(PACT_PARSING_OPTIONS)) #Not load! Otherwise it will try to load Ruby classes.
                          else
                            @params_with_string_keys ||= JSON.parse(request_body, { symbolize_names: false }.merge(PACT_PARSING_OPTIONS)) #Not load! Otherwise it will try to load Ruby classes.
                          end

          if !parsed_params.is_a?(Hash) && !parsed_params.is_a?(Array)
            raise "Expected JSON Object in request body but found #{parsed_params.class.name}"
          end

          parsed_params
        rescue StandardError => e
          raise InvalidJsonError.new(e.message)
        end
        # rubocop: enable Metrics/CyclomaticComplexity

        def params_with_string_keys
          params(symbolize_names: false)
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request(request, identifier_from_path)
        end

        def request_body
          @request_body ||= request.body.to_s
        end

        def any_request_body?
          request_body && request_body.size > 0
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
            char_number, fragment = fragment_before_invalid_utf_8_char(request_body)
            if char_number
              error_message = message("errors.non_utf_8_char_in_request_body", char_number: char_number, fragment: fragment)
              logger.info(error_message)
              set_json_error_message(error_message)
              true
            else
              params
              false
            end
          rescue StandardError => e
            message = "#{e.cause ? e.cause.class.name : e.class.name} - #{e.message}"
            logger.info(message)
            set_json_error_message(message)
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
            if pacticipant.nil?
              set_json_error_message("No #{role} with name '#{name}' found", title: "Not found", type: "not_found", status: 404)
            end
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

        # Ensure we have valid JSON if a JSON body is required OR if a body has been provided
        def content_type_is_json_but_invalid_json_provided?
          content_type_json? && ((request_body_required? || any_request_body?) && invalid_json?)
        end

        def content_type_json?
          request.content_type&.include?("json")
        end

        def request_body_required?
          false
        end

        # TODO rename to put_to_create_supported, otherwise it sounds like it's a policy issue
        # Not a Webmachine method. This is used by security policy code to identify whether
        # a PUT to a non existing resource can create a new object.
        def put_can_create?
          false
        end

        # TODO rename to patch_to_create_supported, otherwise it sounds like it's a policy issue
        # Not a Webmachine method. This is used by security policy code to identify whether
        # a PATCH to a non existing resource can create a new object.
        def patch_can_create?
          false
        end
      end
    end
  end
end
