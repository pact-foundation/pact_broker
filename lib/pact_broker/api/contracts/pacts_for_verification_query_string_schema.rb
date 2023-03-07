require "dry-validation"
require "pact_broker/api/contracts/dry_validation_workarounds"

module PactBroker
  module Api
    module Contracts
      class PactsForVerificationQueryStringSchema < Dry::Validation::Contract
        extend DryValidationWorkarounds
        using PactBroker::HashRefinements

        params do
          optional(:provider_version_tags).maybe(:array?)
          optional(:consumer_version_selectors).each do
            schema do
              required(:tag).filled(:string)
              optional(:latest).filled(included_in?: ["true", "false"])
              optional(:fallback_tag).filled(:string)
              optional(:consumer).filled(:string)
            end
          end
          optional(:include_pending_status).filled(included_in?: ["true", "false"])
          optional(:include_wip_pacts_since).filled(:date)
        end

        def self.call(params)
          flatten_indexed_messages(new.call(params&.symbolize_keys).errors.to_hash)
        end
      end
    end
  end
end
