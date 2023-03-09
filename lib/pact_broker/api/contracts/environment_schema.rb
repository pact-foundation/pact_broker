require "pact_broker/api/contracts/contract_support"

module PactBroker
  module Api
    module Contracts
      class EnvironmentSchema < Dry::Validation::Contract
        include DryValidationMethods

        json do
          optional(:uuid)
          required(:name).filled(:string)
          optional(:displayName).maybe(:string)
          required(:production).filled(included_in?: [true, false])
          optional(:contacts).array(:hash) do
            required(:name).filled(:string)
            optional(:details).hash
          end
        end

        rule(:name).validate(:not_multiple_lines, :no_spaces_if_present)
        rule(:displayName).validate(:not_multiple_lines)

        rule(:name, :uuid) do
          if (environment_with_same_name = PactBroker::Deployments::EnvironmentService.find_by_name(values[:name]))
            if environment_with_same_name.uuid != values[:uuid]
              key.failure(validation_message("environment_name_must_be_unique", name: values[:name]))
            end
          end
        end

        rule(:contacts).each do
          validate_not_multiple_lines(value[:name], key(path.keys + [:name]))
        end
      end
    end
  end
end
