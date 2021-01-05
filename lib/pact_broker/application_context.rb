require 'pact_broker/api/decorators/configuration'

module PactBroker
  class ApplicationContext
    attr_reader :decorator_configuration

    def initialize(overrides = {})
      @decorator_configuration = overrides[:decorator_configuration] || PactBroker::Api::Decorators::Configuration.default_configuration
    end

    def self.default_application_context
      ApplicationContext.new
    end
  end
end
