require "pact_broker/api/contracts/contract_support"

module PactBroker
  module Api
    module Contracts
      class VerificationContract < Dry::Validation::Contract
        include PactBroker::Api::Contracts::DryValidationMethods

        json do
          required(:success).filled(:bool)
          required(:providerApplicationVersion).filled(:string)
          optional(:buildUrl).maybe(:string)
        end

        rule(:providerApplicationVersion).validate(:not_blank_if_present)

        rule(:providerApplicationVersion) do
          validate_version_number(value, key) unless rule_error?(:providerApplicationVersion)
        end

        rule(:buildUrl).validate(:valid_url_if_present)
      end
    end
  end
end
