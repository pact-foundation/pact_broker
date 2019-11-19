require 'dry-validation'
require 'pact_broker/hash_refinements'
require 'pact_broker/api/contracts/dry_validation_workarounds'

module PactBroker
  module Api
    module Contracts
      class VerifiablePactsJSONQuerySchema
        extend DryValidationWorkarounds
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation.Schema do
          optional(:providerVersionTags).maybe(:array?)
          optional(:consumerVersionSelectors).each do
            schema do
              required(:tag).filled(:str?)
              optional(:latest).filled(included_in?: [true, false])
            end
          end
        end

        def self.call(params)
          select_first_message(flatten_indexed_messages(SCHEMA.call(params&.symbolize_keys).messages(full: true)))
        end
      end
    end
  end
end
