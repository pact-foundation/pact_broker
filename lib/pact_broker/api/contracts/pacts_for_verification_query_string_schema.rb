require "dry-validation"
require "pact_broker/api/contracts/dry_validation_workarounds"
require "pact_broker/api/contracts/dry_validation_predicates"

module PactBroker
  module Api
    module Contracts
      class PactsForVerificationQueryStringSchema
        extend DryValidationWorkarounds
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation.Schema do
          configure do
            predicates(DryValidationPredicates)
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)
          end
          optional(:provider_version_tags).maybe(:array?)
          optional(:consumer_version_selectors).each do
            schema do
              required(:tag).filled(:str?)
              optional(:latest).filled(included_in?: ["true", "false"])
              optional(:fallback_tag).filled(:str?)
              optional(:consumer).filled(:str?, :not_blank?)
            end
          end
          optional(:include_pending_status).filled(included_in?: ["true", "false"])
          optional(:include_wip_pacts_since).filled(:date?)
        end

        def self.call(params)
          select_first_message(flatten_indexed_messages(SCHEMA.call(params&.symbolize_keys).messages(full: true)))
        end
      end
    end
  end
end
