module PactBroker
  module Api
    module Resources
      if !defined?(BaseResource)
        BaseResource =  PactBroker.configuration.base_resource_class_factory.call
      end
    end
  end
end
