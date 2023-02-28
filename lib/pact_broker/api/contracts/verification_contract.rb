require "pact_broker/api/contracts/base_contract"
require "pact_broker/api/contracts/dry_validation_macros"
require "pact_broker/api/contracts/dry_validation_methods"

require "uri"

module PactBroker
  module Api
    module Contracts
      class VerificationContract < BaseContract

        property :success
        property :provider_version, as: :providerApplicationVersion
        property :build_url, as: :buildUrl

        validation do
          include PactBroker::Api::Contracts::DryValidationMethods

          json do
            required(:success).filled(:bool)
            required(:provider_version).filled(:string)
            optional(:build_url).maybe(:string)
          end

          rule(:provider_version).validate(:not_blank_if_present)

          rule(:provider_version) do
            validate_version_number(value, key) unless rule_error?(:provider_version)
          end

          rule(:build_url).validate(:valid_url_if_present)
        end
      end
    end
  end
end
