require "pact_broker/api/decorators/configuration"
require "pact_broker/api/contracts/configuration"
require "pact_broker/api/decorators/decorator_context_creator"
require "pact_broker/webhooks/execution_configuration_creator"
require "pact_broker/errors/error_logger"
require "pact_broker/api/resources/error_response_body_generator"

module PactBroker
  class ApplicationContext
    attr_reader :decorator_configuration,
                :api_contract_configuration,
                :decorator_context_creator,
                :webhook_execution_configuration_creator,
                :resource_authorizer,
                :before_resource,
                :after_resource,
                :error_logger,
                :error_response_body_generator

    def initialize(params = {})
      params_with_defaults = {
        decorator_configuration: PactBroker::Api::Decorators::Configuration.default_configuration,
        api_contract_configuration: PactBroker::Api::Contracts::Configuration.default_configuration,
        decorator_context_creator: PactBroker::Api::Decorators::DecoratorContextCreator,
        webhook_execution_configuration_creator: PactBroker::Webhooks::ExecutionConfigurationCreator,
        error_logger: PactBroker::Errors::ErrorLogger,
        error_response_body_generator: PactBroker::Api::Resources::ErrorResponseBodyGenerator
      }.merge(params)

      @decorator_configuration = params_with_defaults[:decorator_configuration]
      @api_contract_configuration = params_with_defaults[:api_contract_configuration]
      @decorator_context_creator = params_with_defaults[:decorator_context_creator]
      @webhook_execution_configuration_creator = params_with_defaults[:webhook_execution_configuration_creator]
      @resource_authorizer = params_with_defaults[:resource_authorizer]
      @before_resource = params_with_defaults[:before_resource]
      @after_resource = params_with_defaults[:after_resource]
      @error_logger = params_with_defaults[:error_logger]
      @error_response_body_generator = params_with_defaults[:error_response_body_generator]

    end

    def self.default_application_context(overrides = {})
      ApplicationContext.new(overrides)
    end
  end
end
