module PactBroker
  class ApplicationContext
    attr_reader :decorator_configuration, :decorator_context_creator, :webhook_execution_configuration_creator,
      :resource_authorizer,
      :before_resource,
      :after_resource

    def initialize(params = {})
      @decorator_configuration = params[:decorator_configuration]
      @decorator_context_creator = params[:decorator_context_creator]
      @webhook_execution_configuration_creator = params[:webhook_execution_configuration_creator]
      @resource_authorizer = params[:resource_authorizer]
      @before_resource = params[:before_resource]
      @after_resource = params[:after_resource]
    end

    def self.default_application_context(overrides = {})
      require 'pact_broker/api/decorators/configuration'
      require 'pact_broker/api/decorators/decorator_context_creator'
      require 'pact_broker/webhooks/execution_configuration_creator'
      defaults = {
        decorator_configuration: PactBroker::Api::Decorators::Configuration.default_configuration,
        decorator_context_creator: PactBroker::Api::Decorators::DecoratorContextCreator,
        webhook_execution_configuration_creator: PactBroker::Webhooks::ExecutionConfigurationCreator
      }
      ApplicationContext.new(defaults.merge(overrides))
    end
  end
end
