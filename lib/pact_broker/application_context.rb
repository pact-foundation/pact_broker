require 'pact_broker/api/decorators/configuration'
require 'pact_broker/api/decorators/decorator_context_creator'
require 'pact_broker/webhooks/execution_configuration_creator'

module PactBroker
  class ApplicationContext
    attr_reader :decorator_configuration, :decorator_context_creator, :webhook_execution_configuration_creator

    def initialize(overrides = {})
      @decorator_configuration = overrides[:decorator_configuration] || PactBroker::Api::Decorators::Configuration.default_configuration
      @decorator_context_creator = PactBroker::Api::Decorators::DecoratorContextCreator
      @webhook_execution_configuration_creator = PactBroker::Webhooks::ExecutionConfigurationCreator
    end

    def self.default_application_context
      ApplicationContext.new
    end
  end
end
