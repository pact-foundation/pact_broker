require 'dry-validation'
require 'pact_broker/api/contracts/dry_validation_workarounds'
require 'pact_broker/api/contracts/dry_validation_predicates'
require 'pact_broker/messages'

module PactBroker
  module Api
    module Contracts
      class PacticipantSchema
        extend DryValidationWorkarounds
        extend PactBroker::Messages
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation.Schema do
          configure do
            predicates(DryValidationPredicates)
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)
          end
          optional(:name).filled(:str?, :single_line?)
          optional(:displayName).maybe(:str?, :single_line?)
          optional(:repositoryUrl).maybe(:str?, :single_line?)
          optional(:repositoryName).maybe(:str?, :single_line?)
          optional(:repositoryOrganization).maybe(:str?, :single_line?)
        end

        def self.call(params_with_string_keys)
          params = params_with_string_keys&.symbolize_keys
          select_first_message(flatten_indexed_messages(SCHEMA.call(params).messages(full: true)))
        end
      end
    end
  end
end
