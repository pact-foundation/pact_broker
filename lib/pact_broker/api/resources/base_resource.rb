require 'pact_broker/api/resources/default_base_resource'

# Allow a previously required definition of the BaseResource to take precedence

module PactBroker
  module Api
    module Resources
      if !defined?(BaseResource)
        BaseResource = DefaultBaseResource
      end
    end
  end
end
