require 'dry-validation'
require 'pact_broker/project_root'

module PactBroker
  module Api
    module Contracts
      module CustomPredicates
        include Dry::Logic::Predicates

        def self.not_blank?(value)
          value.is_a?(String) && value.strip.size > 0
        end
      end

      SCHEMA = Dry::Validation.JSON do
        required(:name).filled(:str?)
        required(:value).maybe(:str?)

        configure do | config |
          predicates(CustomPredicates)
          def self.messages
            super.merge(YAML.load(File.read(PactBroker.project_root.join('lib/pact_broker/locale/en.yml'))))
          end
        end

        rule(:name) { value(:name).not_blank? }
      end

      class SecretContract

        def self.call(params)
          select_first_error(SCHEMA.call(params).errors(full: true))
        end

        def self.select_first_error(errors)
          errors.each_with_object({}) do | (key, value), new_errors |
            new_errors[key] = [value.first]
          end
        end
      end
    end
  end
end
