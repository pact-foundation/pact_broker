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
                :error_reporter,
                :error_response_generator

    def initialize(params)
      @decorator_configuration = params[:decorator_configuration]
      @api_contract_configuration = params[:api_contract_configuration]
      @decorator_context_creator = params[:decorator_context_creator]
      @webhook_execution_configuration_creator = params[:webhook_execution_configuration_creator]
      @resource_authorizer = params[:resource_authorizer]
      @before_resource = params[:before_resource]
      @after_resource = params[:after_resource]
      @error_logger = params[:error_logger]
      @error_reporter = params[:error_reporter]
      @error_response_generator = params[:error_response_generator]
    end

    # TODO pass in configuration
    def self.default_application_context(overrides = {})
      require "pact_broker/api/decorators/configuration"
      require "pact_broker/api/contracts/configuration"
      require "pact_broker/api/decorators/decorator_context_creator"
      require "pact_broker/webhooks/execution_configuration_creator"
      require "pact_broker/errors/error_logger"
      require "pact_broker/errors/error_reporter"
      require "pact_broker/api/resources/error_response_generator"

      params = {
        decorator_configuration: PactBroker::Api::Decorators::Configuration.default_configuration,
        api_contract_configuration: PactBroker::Api::Contracts::Configuration.default_configuration,
        decorator_context_creator: PactBroker::Api::Decorators::DecoratorContextCreator,
        webhook_execution_configuration_creator: PactBroker::Webhooks::ExecutionConfigurationCreator,
        error_logger: PactBroker::Errors::ErrorLogger,
        error_reporter: PactBroker::Errors::ErrorReporter.new(PactBroker.configuration.api_error_reporters),
        error_response_generator: PactBroker::Api::Resources::ErrorResponseGenerator,
      }.merge(overrides)

      ApplicationContext.new(params)
    end
  end
end
