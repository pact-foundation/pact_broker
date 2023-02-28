require "dry-validation"
require "pact_broker/api/contracts/dry_validation_workarounds"
require "pact_broker/api/contracts/dry_validation_macros"

module PactBroker
  module Api
    module Contracts
      class PactsForVerificationQueryStringSchema
        extend DryValidationWorkarounds
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation::Contract.build do
          schema do
            configure do
              config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)
            end
            optional(:provider_version_tags).maybe(:array?)
            optional(:consumer_version_selectors).each do
              schema do
                required(:tag).filled(:str?)
                optional(:latest).filled(included_in?: ["true", "false"])
                optional(:fallback_tag).filled(:str?)
                optional(:consumer).filled(:str?)
              end
            end
            optional(:include_pending_status).filled(included_in?: ["true", "false"])
            optional(:include_wip_pacts_since).filled(:date?)
          end

          rule(:consumer_version_selectors).each do
            key(:consumer).failure(:not_blank?) unless DryValidationPredicates.not_blank?(value[:consumer])
          end
        end

        def self.call(params)
          select_first_message(flatten_indexed_messages(SCHEMA.call(params&.symbolize_keys).messages(full: true)))
        end
      end
    end
  end
end
