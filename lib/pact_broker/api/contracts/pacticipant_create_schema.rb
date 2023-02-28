require "pact_broker/api/contracts/pacticipant_schema"

module PactBroker
  module Api
    module Contracts
      class PacticipantCreateSchema < PactBroker::Api::Contracts::PacticipantSchema
        using PactBroker::HashRefinements

        json do
          required(:name).filled(:string)
        end

        rule(:name).validate(:not_multiple_lines)

        def self.call(params_with_string_keys)
          new.call(params_with_string_keys&.symbolize_keys).errors(full: true).to_hash
        end
      end
    end
  end
end
