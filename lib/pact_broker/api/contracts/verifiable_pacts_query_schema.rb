require 'dry-validation'
require 'pact_broker/api/contracts/dry_validation_workarounds'

module PactBroker
  module Api
    module Contracts
      class VerifiablePactsQuerySchema
        extend DryValidationWorkarounds
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation.Schema do
          optional(:provider_version_tags).maybe(:array?)
          optional(:consumer_version_selectors).each do
            schema do
              required(:tag).filled(:str?)
              optional(:latest).filled(included_in?: ["true", "false"])
            end
          end
          optional(:include_pending_status).filled(included_in?: ["true", "false"])
        end

        def self.call(params)
          select_first_message(flatten_indexed_messages(SCHEMA.call(params&.symbolize_keys).messages(full: true)))
        end
      end
    end
  end
end
