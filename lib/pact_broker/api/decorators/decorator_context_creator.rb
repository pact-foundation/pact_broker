require "pact_broker/api/decorators/decorator_context"

module PactBroker
  module Api
    module Decorators
      class DecoratorContextCreator
        def self.call(resource, options)
          Decorators::DecoratorContext.new(
            resource.base_url,
            resource.resource_url,
            resource.request.env,
            { path_params: resource.identifier_from_path }.merge(options)
          )
        end
      end
    end
  end
end
