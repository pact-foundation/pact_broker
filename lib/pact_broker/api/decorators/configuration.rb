require 'pact_broker/string_refinements'

module PactBroker
  module Api
    module Decorators
      class Configuration
        using PactBroker::StringRefinements

        def initialize(overrides = {})
          @overrides = {}
        end

        def class_for(name)
          @overrides[name] || Object.const_get("PactBroker::Api::Decorators::#{name.to_s.camelcase(true)}")
        end

        def self.default_configuration
          Configuration.new
        end
      end
    end
  end
end
