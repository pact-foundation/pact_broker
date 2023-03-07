require "dry-validation"
require "pact_broker/hash_refinements"
require "pact_broker/string_refinements"
require "pact_broker/api/contracts/dry_validation_methods"
require "pact_broker/api/contracts/dry_validation_macros"
require "pact_broker/api/contracts/consumer_version_selector_contract"

module PactBroker
  module Api
    module Contracts
      class PactsForVerificationJSONQuerySchema < Dry::Validation::Contract
        include DryValidationMethods
        using PactBroker::HashRefinements

        json do
          optional(:providerVersionBranch).filled(:str?)
          optional(:providerVersionTags).maybe(:array?)
          optional(:consumerVersionSelectors).array(:hash)
          optional(:includePendingStatus).filled(included_in?: [true, false])
          optional(:includeWipPactsSince).filled(:date)
        end

        rule(:providerVersionBranch).validate(:not_blank_if_present)
        rule(:consumerVersionSelectors).validate(validate_each_with_contract: ConsumerVersionSelectorContract)

        def self.call(params)
          flatten_indexed_messages(new.call(params&.symbolize_keys).errors.to_hash)
        end
      end
    end
  end
end
