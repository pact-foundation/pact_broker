require "pact_broker/api/contracts/pacticipant_schema"

module PactBroker
  module Api
    module Contracts
      class PacticipantCreateSchema < PactBroker::Api::Contracts::PacticipantSchema
        json do
          required(:name).filled(:string)
        end

        rule(:name).validate(:not_multiple_lines)
      end
    end
  end
end
