require "pact_broker/configuration"

module PactBroker
  module Api
    module Resources
      BaseResource = PactBroker.configuration.base_resource_class_factory.call
    end
  end
end
