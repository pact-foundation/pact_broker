require "pact_broker/api/contracts/contract_support"
require "pact_broker/api/contracts/base_contract"
require "pact_broker/api/contracts/validation_helpers"

module PactBroker
  module Api
    module Contracts
      class PutPacticipantNameContract < Dry::Validation::Contract
        include PactBroker::Api::Contracts::ValidationHelpers
        include PactBroker::Api::Contracts::DryValidationMethods

        json do
          required(:name).maybe(:string)
          required(:name_in_pact).maybe(:string)
        end

        rule(:name, :name_in_pact) do
          if name_in_pact_does_not_match_name_in_url_path?(values)
            key.failure(validation_message("pact_name_in_path_mismatch_name_in_pact", name_in_pact: values[:name_in_pact], name_in_path: values[:name]))
          end
        end

        def name_in_pact_does_not_match_name_in_url_path?(values)
          provided?(values[:name_in_pact]) && values[:name] != values[:name_in_pact]
        end
      end

      class PutPactParamsContract < Dry::Validation::Contract
        include PactBroker::Api::Contracts::DryValidationMethods

        json do
          required(:consumer).filled(:hash)
          required(:provider).filled(:hash)
          required(:consumer_version_number).filled(:string)
        end

        rule(:consumer).validate(validate_with_contract: PutPacticipantNameContract)
        rule(:provider).validate(validate_with_contract: PutPacticipantNameContract)

        rule(:consumer_version_number).validate(:not_blank_if_present)

        rule(:consumer_version_number) do
          validate_version_number(value, key) if !rule_error?(:consumer_version_number)
        end
      end
    end
  end
end
