require "dry-validation"
require "pact_broker/api/contracts/dry_validation_workarounds"
require "pact_broker/api/contracts/dry_validation_macros"
require "pact_broker/messages"

module PactBroker
  module Api
    module Contracts
      class PacticipantSchema
        extend DryValidationWorkarounds
        extend PactBroker::Messages
        using PactBroker::HashRefinements

        SCHEMA = Dry::Validation::Contract.build do
          schema do
            configure do
              config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)
            end
            optional(:name).filled(:str?)
            optional(:displayName).maybe(:str?)
            optional(:mainBranch).maybe(:str?)
            optional(:repositoryUrl).maybe(:str?)
            optional(:repositoryName).maybe(:str?)
            optional(:repositoryNamespace).maybe(:str?)
          end

          rule(:name) do
            key.failure(:single_line?) if key? && !DryValidationPredicates.single_line?(value)
          end
          rule(:displayName) do
            if value
              key.failure(:single_line?) unless DryValidationPredicates.single_line?(value)
              key.failure(:not_blank?) unless DryValidationPredicates.not_blank?(value)
            end
          end
          rule(:mainBranch) do
            if value
              key.failure(:single_line?) unless DryValidationPredicates.single_line?(value)
              key.failure(:no_spaces?) unless DryValidationPredicates.no_spaces?(value)
            end
          end
          rule(:repositoryUrl) do
            key.failure(:single_line?) if key? && !DryValidationPredicates.single_line?(value)
          end
          rule(:repositoryName) do
            key.failure(:single_line?) if key? && !DryValidationPredicates.single_line?(value)
          end
          rule(:repositoryNamespace) do
            key.failure(:single_line?) if key? && !DryValidationPredicates.single_line?(value)
          end
        end

        def self.call(params_with_string_keys)
          params = params_with_string_keys&.symbolize_keys
          select_first_message(flatten_indexed_messages(SCHEMA.call(params).messages(full: true)))
        end
      end
    end
  end
end
