require "pact_broker/string_refinements"

module PactBroker
  module Api
    module Decorators
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
            Object.const_get("PactBroker::Api::Decorators::#{name.to_s.camelcase(true)}")
          end
        end

        # @param [Class] errors_class will be a Hash class or Dry::Validation::MessageSet class
        # @param [String] accept_header if this includes application/problem+json we render a application/problem+json response
        # @return [Class] the decorator class
        def validation_error_decorator_class_for(errors_class, accept_header)
          if accept_header&.include?("application/problem+json")
            if errors_class == Dry::Validation::MessageSet
              PactBroker::Api::Decorators::DryValidationErrorsProblemJSONDecorator
            else
              PactBroker::Api::Decorators::ValidationErrorsProblemJSONDecorator
            end
          else
            if errors_class == Dry::Validation::MessageSet
              PactBroker::Api::Decorators::DryValidationErrorsDecorator
            else
              PactBroker::Api::Decorators::ValidationErrorsDecorator
            end
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
