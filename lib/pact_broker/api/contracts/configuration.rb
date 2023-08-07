require "pact_broker/string_refinements"

# Allow contracts to be accessed by name and configured/overridden for pf

module PactBroker
  module Api
    module Contracts
      class Configuration
        using PactBroker::StringRefinements

        def initialize(overrides = {})
          @overrides = overrides
        end

        def class_for(name)
          if overrides[name].is_a?(String)
            Object.const_get(overrides[name])
          elsif overrides[name].is_a?(Class)
            overrides[name]
          else
            Object.const_get("PactBroker::Api::Contracts::#{name.to_s.camelcase(true)}")
          end
        end

        def self.default_configuration
          Configuration.new
        end

        private

        attr_reader :overrides
      end
    end
  end
end
