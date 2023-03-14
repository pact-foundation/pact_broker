require "pact_broker/api/contracts/base_contract"

module PactBroker
  module Api
    module Contracts
      class PactsForVerificationQueryStringSchema < BaseContract
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
      end
    end
  end
end
