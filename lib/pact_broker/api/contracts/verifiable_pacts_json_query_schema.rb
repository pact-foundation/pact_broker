require 'dry-validation'
require 'pact_broker/hash_refinements'
require 'pact_broker/api/contracts/dry_validation_workarounds'
require 'pact_broker/api/contracts/dry_validation_predicates'

module PactBroker
  module Api
    module Contracts
      class VerifiablePactsJSONQuerySchema
        extend DryValidationWorkarounds
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation.Schema do
          configure do
            predicates(DryValidationPredicates)
          end
          optional(:providerVersionTags).maybe(:array?)
          optional(:consumerVersionSelectors).each do
            schema do
              # configure do
              #   def self.messages
              #     super.merge(en: { errors: { fallbackTagMustBeForLatest: 'can only be set if latest=true' }})
              #   end
              # end

              required(:tag).filled(:str?)
              optional(:latest).filled(included_in?: [true, false])
              optional(:fallbackTag).filled(:str?)

              # rule(fallbackTagMustBeForLatest: [:fallbackTag, :latest]) do | fallback_tag, latest |
              #   fallback_tag.filled?.then(latest.eql?(true))
              # end
            end
          end
          optional(:includePendingStatus).filled(included_in?: [true, false])
          optional(:includeWipPactsSince).filled(:date?)
        end

        def self.call(params)
          select_first_message(flatten_indexed_messages(SCHEMA.call(params&.symbolize_keys).messages(full: true)))
        end
      end
    end
  end
end
