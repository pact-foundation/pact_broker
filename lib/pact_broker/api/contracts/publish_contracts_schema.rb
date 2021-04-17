require 'dry-validation'
require 'pact_broker/api/contracts/dry_validation_workarounds'
require 'pact_broker/api/contracts/dry_validation_predicates'

module PactBroker
  module Api
    module Contracts
      class PublishContractsSchema
        extend DryValidationWorkarounds
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation.Schema do
          configure do
            predicates(DryValidationPredicates)
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)
          end

          required(:pacticipantName).filled(:str?, :not_blank?)
          required(:versionNumber).filled(:not_blank?, :single_line?)
          optional(:tags).each(:not_blank?, :single_line?)
          optional(:branch).maybe(:not_blank?, :single_line?)
          optional(:buildUrl).maybe(:single_line?)

          required(:contracts).each do
            required(:role).filled(included_in?: ["consumer"])
            required(:providerName).filled(:str?, :not_blank?)
            required(:content).filled(:str?, :base64?)
            required(:contentType).filled(included_in?: ["application/json"])
            required(:specification).filled(included_in?: ["pact"])
          end
        end

        def self.call(params)
          select_first_message(flatten_indexed_messages(SCHEMA.call(params&.symbolize_keys).messages(full: true)))
        end
      end
    end
  end
end
