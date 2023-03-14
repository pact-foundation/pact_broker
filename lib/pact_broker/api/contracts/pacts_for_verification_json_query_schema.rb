require "pact_broker/api/contracts/base_contract"
require "pact_broker/api/contracts/consumer_version_selector_contract"

module PactBroker
  module Api
    module Contracts
      class PactsForVerificationJSONQuerySchema < BaseContract
        json do
          optional(:providerVersionBranch).filled(:str?)
          optional(:providerVersionTags).maybe(:array?)
          optional(:consumerVersionSelectors).array(:hash)
          optional(:includePendingStatus).filled(included_in?: [true, false])
          optional(:includeWipPactsSince).filled(:date)
        end

        rule(:providerVersionBranch).validate(:not_blank_if_present)
        rule(:consumerVersionSelectors).validate(validate_each_with_contract: ConsumerVersionSelectorContract)
      end
    end
  end
end
